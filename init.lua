--[[
	StreetsMod: Experimental cars
	
	Documentation:
		initial_properties.weight: float (kilogramm)
		props.max_vel: float (in b/s)
		props.accel: float (in m/s^2)
		props.decel: float (in m/s^2)
		props.brakeDecel: float (in m/s^2)
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
		stepheight = 0.6
	},
	props = {
		max_vel = 15.0,
		accel = 6.25,
		decel = 4.5,
		brakeDecel = 9,
		
		-- Runtime variables
		driver = nil,
		brake = false,
		accelerate = false,
		vel = 0,
		gear = 0,
		steerL = false,
		steerR = false,
		hud = {
			speed,
			gear
		}
	},
	gearT = {
		[-1] = "R",
		[0] = "N",
		[1] = "D"
	},
	update_hud = function(self, finalVelocity)
		if not finalVelocity then
			finalVelocity = {x = 0, z = 0}
		end
		if self.props.driver and self.props.hud.speed ~= nil and self.props.hud.gear ~= nil then
			--Update HUD
			minetest.get_player_by_name(self.props.driver):hud_change(self.props.hud.speed, "text", "Velocity: " .. tostring(math.floor(merge_single_forces(finalVelocity.x, finalVelocity.z) * 3.6)) .. " kn/h")
			minetest.get_player_by_name(self.props.driver):hud_change(self.props.hud.gear, "text", self.gearT[self.props.gear])
		end
	end,
	on_activate = function(self)
		-- Gravity
		self.object:setacceleration({x=0,y= -9.81,z=0})
	end,
	on_rightclick = function(self,clicker)
		if self.props.driver == nil then
			-- Update driver
			self.props.driver = clicker:get_player_name()
			-- Attach player
			clicker:set_attach(self.object, "", {x=0,y=-5,z=0}, {x=0,y=0,z=0})
			-- HUD
			clicker:hud_set_flags({
				hotbar = false,
				healthbar = false,
				crosshair = false,
				wielditem = false
			})
			self.props.hud.speed = clicker:hud_add({
				hud_elem_type = "text",				-- Show text
				position = {x = 0.5, y = 0.9},		-- At this position
				scale = {x = 100, y = 100},			-- In a rectangle of this size
				number = 0xFFFFFF,					-- In this color (hex)
				name = "streets:melcar:speed",		-- called this name
				text = "Velocity: 0 kn/h",			-- value
			})
			self.props.hud.gear = clicker:hud_add({
				hud_elem_type = "text",				-- Show text
				position = {x = 0.1, y = 0.9},		-- At this position
				scale = {x = 100, y = 100},			-- In a rectangle of this size
				number = 0xFFFFFF,					-- In this color (hex)
				name = "streets:melcar:gear",		-- called this name
				text = "N",			-- value
			})
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
				clicker:hud_remove(self.props.hud.speed)
				clicker:hud_remove(self.props.hud.gear)
				self.props.hud.speed = nil
				self.props.hud.gear = nil
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
				self.props.gear = 1
				-- Only accelerate if max_speed not reached and player does not steer
				if self.props.vel < self.props.max_vel and self.props.steerL == false and self.props.steerR == false then
					self.props.vel = self.props.vel + (self.props.accel * dtime)
				end
			else
				self.props.accelerate = false
				-- Decelerate down to more or less 0
				if self.props.vel > 0 then
					self.props.vel = self.props.vel - (self.props.decel * dtime)
				end
			end
			-- down
			if ctrl.down then
				self.props.brake = true
				self.props.accelerate = false
				-- Brake down to more or less 0
				if self.props.vel > 0 then
					self.props.vel = self.props.vel - (self.props.brakeDecel * dtime)
				end
			else
				self.props.brake = false
			end
			-- left
			if ctrl.left then
				self.object:setyaw(self.object:getyaw() + 1 * dtime)
				self.props.steerL = true
			else
				self.props.steerL = false
			end
			-- right
			if ctrl.right then
				self.object:setyaw(self.object:getyaw() - 1 * dtime)
				self.props.steerR = true
			else
				self.props.steerR = false
			end
		end
		-- Stop if very slow (e.g. because driver brakes)
		if math.abs(merge_single_forces(self.object:getvelocity().x, self.object:getvelocity().z)) < 0.1 and self.props.accelerate == false then
			self.object:setvelocity({x = 0,y = self.object:getvelocity().y,z = 0})
			self.props.gear = 0
			self:update_hud()
			return
		end
		
		--Apply velocity
		local finalVelocity = force2vec(self, {
			dir = self.object:getyaw(),
			force = self.props.vel
		})
		-- Copy y velocity (caused by gravity) to make sure it doesn't get overriden
		finalVelocity.y = self.object:getvelocity().y
		self.object:setvelocity(finalVelocity)
		self:update_hud(finalVelocity)
	end
})