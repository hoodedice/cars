--[[
	StreetsMod: Experimental cars
]]
local function get_single_accels(p)
	local output = {x = 0, y = 0, z = 0}
	local alpha = p.dir
	local beta = 180 - 90 - alpha
	local hyp = p.accel
	output.x = math.sin(alpha) * hyp
	output.z = math.sin(beta) * hyp
	return output
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
		brake_factor = 1,
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
				self.props.brake = 1
				if self.props.rpm < self.props.max_rpm then
					self.props.rpm = self.props.rpm + 40
				end
			else
				if self.props.rpm >= 520 then
					self.props.rpm = self.props.rpm - 20
				end
			end
			-- down
			if ctrl.down then
				self.props.brake = -1
				if self.props.rpm >= 520 then
					self.props.rpm = self.props.rpm - 40
				end
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
		if self.props.brake == 1 then
			local accel = (self.props.rpm / 1000 - 0.5) * self.props.gear * self.props.brake_factor
			self.object:setacceleration(get_single_accels({
				dir = self.object:getyaw(),
				accel = accel
			}))
		end
	end
})