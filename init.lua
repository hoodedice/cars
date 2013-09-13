--[[
	StreetsMod: Experimental cars
]]
minetest.register_entity(":streets:melcar",{
	initial_properties = {
		hp_max = 100,
		physical = true,
		weight = 100,
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
		speed = 0,
		accel = 4,
		decel = 6,
		gears = 3,
		shift_time = 0.75,
	},
	on_rightclick = function(self,clicker)
		if self.props.driver == nil then
			-- Update driver
			self.props.driver = clicker:get_player_name()
			-- Attach player
			clicker:set_attach(self.object, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
		else
			if self.props.driver == clicker:get_player_name() then
				-- Update driver
				self.props.driver = nil
				-- Detach player
				clicker:set_detach()
			else
				minetest.chat_send_player(clicker:get_player_name(),"This car already has a driver")
			end
		end
	end,
	on_step = function(self,dtime)
		minetest.chat_send_all(self.object:getvelocity().z .. " of " .. self.props.max_speed)
		if self.props.driver then
			local ctrl = minetest.get_player_by_name(self.props.driver):get_player_control()
			-- If player moves, move the car
			if ctrl.up then
				-- Only accelerate if speed < max_speed
				if self.object:getvelocity().z >= self.props.max_speed then
					self.object:setacceleration({x=0,y=0,z=0})
				else
					self.object:setacceleration({x=0,y=0,z= self.props.accel})
				end
			else
				-- Stop if speed < 0.5
				if self.object:getvelocity().z <= 0.5 then
					self.object:setacceleration({x=0,y=0,z=0})
					self.object:setvelocity({x=0,y=0,z=0})
				else
					self.object:setacceleration({x=0,y=0,z= self.props.decel * -1})
				end
			end
			if ctrl.down then

			end
		else
			
		end
		-- Gravity
		local pos = self.object:getpos()
		pos.y = math.floor(pos.y)
		if minetest.get_node(pos).name == "air" then
			-- Fall if air under car
			self.object:setacceleration({x=0,y=-1 * self.initial_properties.weight / 10,z=0})
			self.props.on_ground = false
		else
			if self.props.on_ground == false then
				-- Stop falling if on ground
				minetest.after(1,function()
					self.object:setacceleration({x=0,y=0,z=0})
					self.object:setvelocity({x=0,y=0,z=0})
					self.props.on_ground = true
				end)
			end
		end
		-- Update properties
		self.props.speed = self.object:getvelocity()
	end
})