
-- Convenience function
function nuke:get_tiles(name)
	local side = name.."_side.png"
	return {name.."_top.png", name.."_bottom.png",
		side, side, side, side}
end


-- Atomic nuke
minetest.register_craft({
	output = "nuke:atomic 1",
	recipe = {
		{"nuke:mese", "nuke:mese", "nuke:mese"},
		{"nuke:mese", "technic:uranium_fuel",   "nuke:mese"},
		{"nuke:mese", "nuke:mese", "nuke:mese"}
	}
})

nuke:register_nuke("nuke:atomic",
		"Atomic nuke",
		tonumber(nuke.config:get("atomic_radius")),
		nuke:get_tiles("nuke_atomic"))



-- Mese nuke
minetest.register_craft({
	output = "nuke:mese 3",
	recipe = {
		{"nuke:iron",            "default:mese_crystal", "nuke:iron"},
		{"default:mese_crystal", "nuke:iron",            "default:mese_crystal"},
		{"nuke:iron",            "default:mese_crystal", "nuke:iron"}
	}
})


nuke:register_nuke("nuke:mese",
		"Mese nuke",
		tonumber(nuke.config:get("mese_radius")),
		nuke:get_tiles("nuke_mese"))


-- Iron nuke
minetest.register_craft({
	output = "nuke:iron 3",
	recipe = {
		{"nuke:tnt",            "default:steel_ingot", "nuke:tnt"},
		{"default:steel_ingot", "nuke:tnt",            "default:steel_ingot"},
		{"nuke:tnt",            "default:steel_ingot", "nuke:tnt"}
	}
})

nuke:register_nuke("nuke:iron",
		"Iron nuke",
		tonumber(nuke.config:get("iron_radius")),
		nuke:get_tiles("nuke_iron"))


-- Normal TNT
minetest.register_craft({
	output = 'nuke:tnt 3',
	recipe = {
		{"default:coal_lump", "default:sand",      "default:coal_lump"},
		{"default:sand",      "default:coal_lump", "default:sand"},
		{"default:coal_lump", "default:sand",      "default:coal_lump"}
	}
})

nuke:register_nuke("nuke:tnt",
		"TNT",
		tonumber(nuke.config:get("tnt_radius")),
		nuke:get_tiles("default_tnt"))

