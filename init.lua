--[[
	StreetsMod: Experimental cars
]]
local function get_single_accels(p)
	local output = {x = 0, y = 0, z = 0}
	local alpha = p.dir
	local beta = 180 - 90 - alpha
	local hyp = p.accel
	output.x = math.sin(alpha) * hyp * -1
	output.z = math.sin(beta) * hyp
	return output
end

local function merge_single_forces(x,z)
	return math.sqrt(math.pow(x,2) + math.pow(z,2))
end

minetest.register_entity(":streets:melcar",{
	initial_properties = {
		hp_max = 100,
		physical = true,
		weight = 1,	-- ( in tons)
		visual = "mesh",
		mesh = "car_001.obj",
		visual_size = {x=1,y=1},
		textures = {"textur_yellow.png"},
		collisionbox = {-0.5,0.0,-1.85,1.35,1.5,1.25},
		stepheight = 0.5
	},
	props = {
		driver = nil,
		on_ground = false,
		max_speed = 10.0,
		max_rpm = 4000,
		accel = 4,
		decel = 6,
		gears = 3,
		shift_time = 0.75,
		
		-- Runtime variables
		speed = 0,
		rpm = 0,
		gear = 0,
		brake = false,
		accelerate = false,
		hud = {
			gear,
			rpm,
		}
	},
	on_activate = function(self)
		-- Gravity
		self.object:setacceleration({x=0,y= self.initial_properties.weight * 9.81 * -1,z=0})
		self.props.rpm = 500
		self.props.gear = 1
	end,
	on_rightclick = function(self,clicker)
		if self.props.driver == nil then
			-- Update driver
			self.props.driver = clicker:get_player_name()
			-- Attach player
			clicker:set_attach(self.object, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
			-- HUD
			clicker:hud_set_flags({
				hotbar = false,
				healthbar = false,
				crosshair = false,
				wielditem = false
			})
			self.props.hud.rpm = clicker:hud_add({
				hud_elem_type = "text",
				position = {x=0.1,y=0.9},
				name = "Gear",
				scale = {x=100,y=100},
				text = "1",
				number = 0xFFFFFF
			})
			-- Start engine
			self.props.engine_rpm = 500
			self.props.gear = 1
		else
			if self.props.driver == clicker:get_player_name() then
				-- Update driver
				self.props.driver = nil
				-- Detach player
				clicker:set_detach()
				-- HUD
				clicker:hud_set_flags({
					hotbar = true,
					healthbar = true,
					crosshair = true,
					wielditem = true
				})
			else
				minetest.chat_send_player(clicker:get_player_name(),"This car already has a driver")
			end
		end
	end,
	on_step = function(self,dtime)
		-- Player controls
		if self.props.driver then
			local ctrl = minetest.get_player_by_name(self.props.driver):get_player_control()
			-- up
			if ctrl.up then
				self.props.brake = false
				self.props.accelerate = true
				if self.props.rpm < self.props.max_rpm then
					self.props.rpm = self.props.rpm + 40
				end
			else
				self.props.accelerate = false
				if self.props.rpm >= 520 then
					self.props.rpm = self.props.rpm - 20
				end
			end
			-- down
			if ctrl.down then
				self.props.brake = true
				self.props.accelerate = false
				if self.props.rpm >= 520 then
					self.props.rpm = self.props.rpm - 40
				end
			else
				self.props.brake = false
			end
			-- left
			if ctrl.left then
				self.object:setyaw(self.object:getyaw() + 1 * dtime)
			end
			-- right
			if ctrl.right then
				self.object:setyaw(self.object:getyaw() - 1 * dtime)
			end
		end
		-- Calculate acceleration
		if self.props.brake == false then
			local accel = (self.props.rpm / 1000 - 0.5) * self.props.gear
			self.object:setacceleration(get_single_accels({
				dir = self.object:getyaw(),
				accel = accel
			}))
		else
			if merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z) > 0.1 then
				self.object:setacceleration(get_single_accels({
					dir = self.object:getyaw(),
					accel = -8
				}))
			end
		end
		-- Stop if very slow (e.g. because driver brakes)
		minetest.chat_send_all("Accel: " .. tostring(self.props.accelerate) .. ", Brake: " .. tostring(self.props.brake))
		if math.abs(merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z)) < 1 and self.props.accelerate == false and self.props.brake == false then
			self.object:setacceleration({x=0,y=0,z=0})
			self.object:setvelocity({x=0,y=0,z=0})
		end
	end
})