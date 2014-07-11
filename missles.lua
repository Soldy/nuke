
local radius = assert(tonumber(nuke.config:get("missle_radius")),
		"missle_radius must be convertible to a number")
local misfire_radius = assert(tonumber(nuke.config:get("missle_misfire_radius")),
		"missle_misfire_radius must be convertible to a number")

local function get_missle(pos)
	for _, o in pairs(minetest.get_objects_inside_radius(pos, 1)) do
		local e = o:get_luaentity()
		if e and e.name == "nuke:missle" then
			return e
		end
	end
end

local function launch_missle(pos, strike_pos)
	local e = get_missle(pos)
	if not e then return end
	e.state = 1
	e.origin = pos
	e.strike_pos = strike_pos
	local ppos = vector.new(pos)
	ppos.y = ppos.y + 2
	minetest.add_particlespawner({
		amount = 128,
		time = 1,
		minpos = ppos,
		maxpos = ppos,
		minvel = {x=-5, y=-10, z=-5},
		maxvel = {x=5,  y=0,  z=5},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 3,
		minsize = 4,
		maxsize = 6,
		collisiondetection = true,
		texture = "nuke_smoke_dark.png",
	})
end

local function get_controller_formspec(strike_pos)
	return "size[4,1.5]"
		.."field[0.3,0.5;4,1;pos;Position to strike;"
		..minetest.formspec_escape(minetest.pos_to_string(strike_pos)).."]"
		.."button_exit[0,1;2,1;save;Save]"
		.."button_exit[2,1;2,1;fire;Fire!]"
end

minetest.register_entity("nuke:missle", {
	textures = {"nuke_missle.png"},
	visual = "mesh",
	mesh = "nuke_missle.x",
	visual_size = {x=3, y=3, z=3},
	phisical = true,
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 4, 0.5},
	state = 0,
	--origin = vector.new(),
	on_activate = function(self, static_data)
		if static_data == "" then return end
		for k, v in pairs(minetest.deserialize(static_data)) do
			self[k] = v
		end
	end,
	on_step = function(self, dtime)
		local o = self.object
		local pos = vector.round(o:getpos())
		local node = minetest.get_node(pos)

		if self.state == 0 then
			if not vector.equals(self.object:getvelocity(), {x=0, y=0, z=0}) then
				-- We are in standby but moving, probably got unloaded
				-- Drop ourselves
				minetest.add_item(pos, "nuke:missle")
				assert(false)
			end
			return
		elseif self.state == 1 then
			o:setacceleration({x=0, y=10, z=0})
			if pos.y >= self.origin.y + 100 then
				local dir = vector.direction(pos, self.strike_pos)
				dir = vector.normalize(dir)
				dir = vector.multiply(dir, 20)
				o:setvelocity(dir)
				o:setacceleration({x=0, y=0, z=0})
				self.state = 2
			end
			if node.name ~= "air" and pos.y >= self.origin.y + 2 then
				nuke:explode(pos, misfire_radius)
				o:remove()
			end
		elseif self.state == 2 then
			if node.name ~= "air" then
				nuke:explode(pos, radius)
				o:remove()
			end
		end
	end,
	on_punch = function(self, player)
		player:get_inventory():add_item("main", "nuke:missle")
	end,
	get_staticdata = function(self)
		if self.state == 0 then
			return ""
		end
		return minetest.serialize({
			state = self.state,
			origin = self.origin,
			strike_pos = self.strike_pos,
		})
	end,
})

minetest.register_node("nuke:missle_controller", {
	tiles = {"nuke_missle_controller_top.png", "nuke_missle_controller.png",
	         "nuke_missle_controller.png",     "nuke_missle_controller.png",
	         "nuke_missle_controller.png",     "nuke_missle_controller.png"},
	groups = {cracky=1},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3, -0.5, -0.3, 0.3, 1,   0.3}, -- Base
			{-0.5, 1,    -0.5, 0.5, 1.2, 0.5}, -- Top
			{-0.5, 1.2,  0,    0.5, 1.4, 0.5}, -- Half top
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local pos_str = minetest.pos_to_string(pos)
		meta:set_string("strikepos", pos_str)
		meta:set_string("infotext", "Missle controller")
		meta:set_string("formspec", get_controller_formspec(pos))
	end,
	on_receive_fields = function(pos, formname, fields, player)
		if not fields.pos then return end
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local strike_pos = minetest.string_to_pos(fields.pos)
		if not strike_pos then return end
		local player_name = player:get_player_name()
		if vector.distance(pos, strike_pos) > 500 then
			minetest.chat_send_player(player_name, "Strike position is too far.")
			return
		end
		meta:set_string("strikepos", minetest.pos_to_string(strike_pos))
		meta:set_string("formspec", get_controller_formspec(strike_pos))
		if fields.fire then
			if not nuke:can_detonate(player_name) then
				minetest.chat_send_player(player_name, "You can't detonate nukes!")
				return
			end
			local dir = minetest.facedir_to_dir(node.param2)
			dir = vector.multiply(dir, 2)  -- The launcher is two nodes behind us
			local launcher_pos = vector.add(pos, dir)
			launch_missle(launcher_pos, strike_pos)
		end
	end,
})

minetest.register_node("nuke:missle_launcher", {
	tiles = {"nuke_missle_launcher.png"},
	groups = {cracky=1},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			--{-1,   -0.3, -0.2, -0.8, 4,  0.2}, -- Left bar
			--{0.8,  -0.3, -0.2, 1,    4,  0.2}, -- Right bar
			{-0.2, -0.3, 0.8,  0.2,  4,    1},   -- Back bar
			{-0.4, 3.8,  0.2,  -0.2, 4,    1},   -- Left holder
			{0.2,  3.8,  0.2,  0.4,  4,    1},   -- Right holder
			{-1,   -0.5, -1,   1,    -0.3, 1}, -- Base
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Missle launcher")
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		if get_missle(pos) then
			return itemstack
		end
		if itemstack:get_name() == "nuke:missle" then
			itemstack:take_item()
			minetest.add_entity(pos, "nuke:missle")
		end
		return itemstack
	end,
	after_dig_node = function(pos, node, meta, player)
		local e = get_missle(pos)
		if e then
			e.object:remove()
			player:get_inventory():add_item("main", "nuke:missle")
		end
	end,
})

minetest.register_craftitem("nuke:missle", {
	description = "Missle",
	inventory_image = "nuke_missle_wield.png",
	wield_image = "nuke_missle_wield.png",
	stack_max = 1,
})
