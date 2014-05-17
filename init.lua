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
dofile(minetest.get_modpath("cars") .. "/melcar.lua")

gearT = {
	[-1] = "R",
	[0] = "N",
	[1] = "D"
}