minetest.register_node("golden_apple:golden_apple", {
	description = "Golden Apple",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"apple_golden.png"},
	inventory_image = "apple_golden.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {fleshy=3,dig_immediate=3,flammable=2},
	on_use = minetest.item_eat(20),
})

minetest.register_craft( {
	output = "golden_apple:golden_apple",
	recipe = {
		{ "default:gold_ingot","default:gold_ingot","default:gold_ingot"},
		{ "default:gold_ingot","default:apple",     "default:gold_ingot"},
		{ "default:gold_ingot","default:gold_ingot","default:gold_ingot"},
	}	
})

