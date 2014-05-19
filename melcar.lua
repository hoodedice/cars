local melcar = {
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
		name = "Melcar",
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
			gear,
			name,
			radio
		}
	}
}

function melcar:on_activate(staticdata)
	-- Gravity
	self.object:setacceleration({x=0,y= -9.81,z=0})
end

function melcar:on_rightclick(clicker)
	if self.props.driver == nil then
		-- Update driver
		self.props.driver = clicker:get_player_name()
		-- Attach player
		clicker:set_attach(self.object, "passenger1", {x=0,y=-5,z=0}, {x=0,y=0,z=0})
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
			text = "N",							-- value
		})
		self.props.hud.name = clicker:hud_add({
			hud_elem_type = "text",				-- Show text
			position = {x = 0.9, y = 0.9},		-- At this position
			scale = {x = 100, y = 100},			-- In a rectangle of this size
			number = 0xFFFFFF,					-- In this color (hex)
			name = "streets:melcar:name",		-- called this name
			text = self.props.name,				-- value
		})
		self.props.hud.radio = clicker:hud_add({
			hud_elem_type = "text",				-- Show text
			position = {x = 0.5, y = 0.1},		-- At this position
			scale = {x = 100, y = 100},			-- In a rectangle of this size
			number = 0xFFFFFF,					-- In this color (hex)
			name = "streets:melcar:radio",		-- called this name
			text = tostring(radio[math.random(1, #radio)]),				-- value
		})
		-- Timeout for name (like in GTA)
		minetest.after(3, function()
			if self.props.driver then
				minetest.get_player_by_name(self.props.driver):hud_remove(self.props.hud.name)
			end
		end)
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
			clicker:hud_remove(self.props.hud.name)
			clicker:hud_remove(self.props.hud.radio)
			self.props.hud.speed = nil
			self.props.hud.gear = nil
			self.props.hud.name = nil
			self.props.hud.radio = nil
		else
			minetest.chat_send_player(clicker:get_player_name(),"This car already has a driver")
		end
	end
end

function melcar:on_step(dtime)
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
		if ctrl.left and ctrl.up then
			local driver = minetest.get_player_by_name(self.props.driver)
			self.object:setyaw(self.object:getyaw() + math.pi / 120 + dtime * math.pi / 120)
			driver:set_look_yaw(self.object:getyaw() + math.pi / 120 + dtime * math.pi / 120)
			self.props.steerL = true
		else
			self.props.steerL = false
		end
		-- right
		if ctrl.right and ctrl.up then
			local driver = minetest.get_player_by_name(self.props.driver)
			self.object:setyaw(self.object:getyaw() - math.pi / 120 - dtime * math.pi / 120)
			driver:set_look_yaw(self.object:getyaw() + math.pi / 120 + dtime * math.pi / 120)
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

function melcar:update_hud(v)
	if not v then
		v = {x = 0, z = 0}
	end
	if self.props.driver and self.props.hud.speed ~= nil and self.props.hud.gear ~= nil then
		--Update HUD
		minetest.get_player_by_name(self.props.driver):hud_change(self.props.hud.speed, "text", "Velocity: " .. tostring(math.floor(merge_single_forces(v.x, v.z) * 3.6)) .. " kn/h")
		minetest.get_player_by_name(self.props.driver):hud_change(self.props.hud.gear, "text", gearT[self.props.gear])
	end
end

-- Register
minetest.register_entity(":streets:melcar", melcar)

minetest.register_craftitem(":streets:melcar_spawner", {
	description = "Melcar",
	inventory_image = "streets_melcar_inv.png",
	wield_image = "streets_melcar_inv.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		pointed_thing.under.y = pointed_thing.under.y+0.5
		minetest.env:add_entity(pointed_thing.under, "streets:melcar")
		itemstack:take_item()
		return itemstack
	end,
})