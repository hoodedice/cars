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
		textures = {"textur_black.png"}
	},
	props = {
		driver = nil,
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
		if self.props.driver then
			local ctrl = minetest.get_player_by_name(self.props.driver):get_player_control()
			-- If player moves, move the car
			if ctrl.up then
				minetest.chat_send_all("up")
			elseif ctrl.down then
				minetest.chat_send_all("down")
			elseif ctrl.left then
				minetest.chat_send_all("left")
			elseif ctrl.right then
				minetest.chat_send_all("right")
			end
		end
		-- Gravity
		local pos = self.object:getpos()
		pos.y = math.floor(pos.y)
		if minetest.get_node(pos).name == "air" then
			self.object:setacceleration({x=0,y=-1 * self.initial_properties.weight / 10,z=0})
		else
			self.object:setacceleration({x=0,y=0,z=0})
			self.object:setvelocity({x=0,y=0,z=0})
		end
	end
})