--[[
	StreetsMod: Experimental cars
]]
minetest.register_entity(":streets:melcar",{
	initial_properties = {
		hp_max = 100,
		physical = true,
		weight = 1,	-- ( in tons)
		visual = "mesh",
		mesh = "car_001.obj",
		visual_size = {x=1,y=1},
		textures = {"textur_yellow.png"},
		collisionbox = {-0.5,0.0,-1.85,1.35,1.5,1.25}
	},
	props = {
		driver = nil,
		on_ground = false,
		max_speed = 10.0,
		accel = 4,
		decel = 6,
		gears = 3,
		shift_time = 0.75,
		
		-- Runtime variables
		speed = 0,
		engine_rpm = 0,
		gear = 0,
		hud = {
			gear,
			rpm,
		}
	},
	on_activate = function(self)
		-- Gravity
		self.object:setacceleration({x=0,y= self.initial_properties.weight * 9.81 * -1,z=0})
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
		minetest.chat_send_all(self.props.engine_rpm)
		-- Engine RPM, used to calculate the speed
		if self.props.driver then
			local ctrl = minetest.get_player_by_name(self.props.driver):get_player_control()
			-- If player moves, move the car
			if ctrl.up then
				if self.props.engine_rpm < 5000 then
					self.props.engine_rpm = self.props.engine_rpm + 25
				end
			else
				if self.props.engine_rpm >= 520 then
					self.props.engine_rpm = self.props.engine_rpm - 20
				end
			end
			if ctrl.down then
				self.props.gear = -1
			end
		else
			
		end
		-- Calculate speed
			if self.props.engine_rpm >= 550 then
				self.object:setacceleration({x= self.props.engine_rpm / 1000 * self.props.gear ,y=0,z=0})
			elseif self.props.rpm <= 550 then
				self.object:setacceleration({x=0,y=0,z=0})
			end
		-- Update properties
		self.props.speed = self.object:getvelocity()
		-- Update HUD
		if self.props.driver then
			--
		end
	end
})