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
	end
})