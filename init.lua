--[[
	StreetsMod: Experimental cars
]]
dofile(minetest.get_modpath("cars") .. "/physHelpers.lua")

minetest.register_entity(":streets:melcar",{
	initial_properties = {
		hp_max = 100,
		physical = true,
		weight = 1000,	-- ( in kg)
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
		accel = 1.5,
		decel = 1,
		gears = 5,
		shift_time = 0.75,
		
		-- Runtime variables
		speed = 0,
		rpm = 0,
		gear = 0,
		brake = false,
		accelerate = false,
		sound = nil,
		hud = {
			gear,
			rpm,
		},
		forces = {
			{x = 0, y = -9.81, z = 0}
		},
	},
	on_activate = function(self)
		-- Gravity
		--self.object:setacceleration({x=0,y= -9.81,z=0})
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
					self.props.rpm = self.props.rpm + 20
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
					self.props.rpm = self.props.rpm - 20
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
			accel = (self.props.rpm - 500) * self.props.accel
			table.insert(self.props.forces, force2vec(self, {
				dir = self.object:getyaw(),
				accel = accel
			}))
		else
			if merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z) > 0.1 then
				table.insert(self.props.forces, force2vec(self,{
					dir = self.object:getyaw(),
					accel = -8000 * self.props.decel
				}))
			end
		end
		-- Slow down, if car doesn't accelerate
		if self.props.accelerate == false and self.props.brake == false then
			table.insert(self.props.forces, force2vec(self,{
				dir = self.object:getyaw(),
				accel = -2000
			}))
		end
		-- Stop acceleration if max_speed reached
		if merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z) >= self.props.max_speed and self.props.brake == false then
			self.object:setacceleration({x = 0, y= -9.81, z = 0})
			self.props.forces = {
				{x = 0, y = -9.81, z = 0}
			}
		end
		-- Stop if very slow (e.g. because driver brakes)
		if math.abs(merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z)) < 0.1 and self.props.accelerate == false then
			self.object:setacceleration({x=0,y= -9.81 ,z=0})
			self.object:setvelocity({x=0,y=0,z=0})
			self.props.forces = {
				{x = 0, y = -9.81, z = 0}
			}
		end
		
		local res = {x = 0, y = -9.81, z = 0}
		local allX = {}
		local allY = {}
		local allZ = {}
		
		for k, v in pairs(self.props.forces) do
			table.insert(allX, v.x)
			table.insert(allY, v.y)
			table.insert(allZ, v.z)
		end
		
		for k, v in pairs(allX) do
			res.x = res.x + v
		end
		res.x = res.x / #allX
		for k, v in pairs(allY) do
			res.y = res.y + v
		end
		res.y = res.y / #allY
		for k, v in pairs(allZ) do
			res.z = res.z + v
		end
		res.z = res.z / #allZ
		
		-- Acceleration = Force / Weight
		res.x = res.x / self.initial_properties.weight
		res.z = res.z / self.initial_properties.weight
		
		self.object:setacceleration(res)
		minetest.chat_send_all("RPM: " .. self.props.rpm .. " | A: " .. accel)
		minetest.chat_send_all("Resulting (out of " .. #self.props.forces .. " forces: " .. minetest.serialize(res))
		
		self.props.forces = {
			{x = 0, y = -9.81, z = 0}
		}
	end
})