-- Font: 04.jp.org

-- load characters map
local chars_file = io.open(minetest.get_modpath("signs").."/characters", "r")
local charmap = {}
local charlen = {}
local max_chars = 16
if not chars_file then
    print("[signs] E: character map file not found")
else
    while true do
        local char = chars_file:read("*l")
        if char == nil then
            break
        end
        local img = chars_file:read("*l")
        local clen = chars_file:read("*l")
        charmap[char] = img
	charlen[char] = clen
    end
end

local signs = {
    {delta = {x = 0, y = 0, z = 0.399}, yaw = 0},
    {delta = {x = 0.399, y = 0, z = 0}, yaw = math.pi / -2},
    {delta = {x = 0, y = 0, z = -0.399}, yaw = math.pi},
    {delta = {x = -0.399, y = 0, z = 0}, yaw = math.pi / 2},
}

local signs_yard = {
    {delta = {x = 0, y = 0, z = -0.05}, yaw = 0},
    {delta = {x = -0.05, y = 0, z = 0}, yaw = math.pi / -2},
    {delta = {x = 0, y = 0, z = 0.05}, yaw = math.pi},
    {delta = {x = 0.05, y = 0, z = 0}, yaw = math.pi / 2},
}

local sign_groups = {choppy=2, dig_immediate=2,not_in_creative_inventory=1}

local construct_sign = function(pos)
    local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "field[text;;${text}]")
	meta:set_string("infotext", "")
end

local destruct_sign = function(pos)
    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    for _, v in ipairs(objects) do
        if v:get_entity_name() == "signs:text" then
            v:remove()
        end
    end
end

local update_sign = function(pos, fields)
    local meta = minetest.get_meta(pos)
	if fields then
		meta:set_string("text", fields.text)
	end
	meta:set_string("infotext", "")
    local text = meta:get_string("text")
    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    for _, v in ipairs(objects) do
        if v:get_entity_name() == "signs:text" then
            v:set_properties({textures={generate_texture(create_lines(text))}})
			return
        end
    end
	
	-- if there is no entity
	local sign_info
	if minetest.get_node(pos).name == "signs:sign_yard" then
		sign_info = signs_yard[minetest.get_node(pos).param2 + 1]
	elseif minetest.get_node(pos).name == "signs:sign_wall" then
		sign_info = signs[minetest.get_node(pos).param2 + 1]
	end
	if sign_info == nil then
		return
	end
	local text = minetest.add_entity({x = pos.x + sign_info.delta.x,
										y = pos.y + sign_info.delta.y,
										z = pos.z + sign_info.delta.z}, "signs:text")
	text:setyaw(sign_info.yaw)
end

local function is_wall(wallparam)
	if wallparam == 0 then return false end
	local para2 = 0
	if wallparam == 2 then
		para2 = 1
	elseif wallparam == 3 then
		para2 = 3
	elseif wallparam == 4 then
		para2 = 0
	elseif wallparam == 5 then
		para2 = 2
	end
	return para2
end

minetest.register_abm({
	nodenames = {"default:sign_wall"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local n = minetest.get_node(pos)
		local def = minetest.registered_nodes[n.name]
		if def then
			local wdir = n.param2
    local meta = minetest.get_meta(pos)
    local text = meta:get_string("text")

			if wdir == 0 then
				minetest.remove_node(pos)
			elseif wdir == 1 then
				minetest.set_node(pos, {name = "signs:sign_yard", param2 = 1})
			else
				minetest.set_node(pos, {name = "signs:sign_wall", param2 = is_wall(wdir)})
			end
	    local meta = minetest.get_meta(pos)
		meta:set_string("text", text)
			update_sign(pos)
		end
	end
})

minetest.register_craftitem(":default:sign_wall", {
    description = "Sign",
    inventory_image = "sign.png",
    wield_image = "sign.png",
    on_place = function(itemstack, placer, pointed_thing)
        local above = pointed_thing.above
        local under = pointed_thing.under
        local dir = {x = under.x - above.x,
                     y = under.y - above.y,
                     z = under.z - above.z}

        local wdir = minetest.dir_to_wallmounted(dir)

        local placer_pos = placer:getpos()
        if placer_pos then
            dir = {
                x = above.x - placer_pos.x,
                y = above.y - placer_pos.y,
                z = above.z - placer_pos.z
            }
        end

        local fdir = minetest.dir_to_facedir(dir)

        local sign_info
        if wdir == 0 then
            --how would you add sign to ceiling?
            minetest.add_item(above, "signs:sign_wall")
			itemstack:take_item()
			return itemstack
        elseif wdir == 1 then
            minetest.add_node(above, {name = "signs:sign_yard", param2 = fdir})
            sign_info = signs_yard[fdir + 1]
        else
            minetest.add_node(above, {name = "signs:sign_wall", param2 = fdir})
            sign_info = signs[fdir + 1]
        end

        local text = minetest.add_entity({x = above.x + sign_info.delta.x,
                                              y = above.y + sign_info.delta.y,
                                              z = above.z + sign_info.delta.z}, "signs:text")
        text:setyaw(sign_info.yaw)

	if not minetest.setting_getbool("creative_mode") then
		itemstack:take_item()
	end
        return itemstack
    end,
})

minetest.register_node("signs:sign_wall", {
    description = "Sign",
    inventory_image = "default_sign_wall.png",
    wield_image = "default_sign_wall.png",
    node_placement_prediction = "",
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "facedir",
    walkable = false,
    drop = "default:sign_wall",
    drawtype = "nodebox",
    node_box = {type = "fixed", fixed = {-0.45, -0.15, 0.4, 0.45, 0.45, 0.498}},
    selection_box = {type = "fixed", fixed = {-0.45, -0.15, 0.4, 0.45, 0.45, 0.498}},
    tiles = {"default_wood_pale.png"},
    groups = sign_groups,
    on_construct = function(pos)
        construct_sign(pos)
    end,
    on_destruct = function(pos)
        destruct_sign(pos)
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        update_sign(pos, fields)
    end,
	on_punch = function(pos, node, puncher)
		update_sign(pos)
	end,
})

minetest.register_node("signs:sign_yard", {
    paramtype = "light",
	sunlight_propagates = true,
    paramtype2 = "facedir",
    drawtype = "nodebox",
    walkable = false,
    node_box = {type = "fixed", fixed = {
        {-0.45, -0.15, -0.049, 0.45, 0.45, 0.049},
        {-0.05, -0.5, -0.049, 0.05, -0.15, 0.049}
    }},
    selection_box = {type = "fixed", fixed = {-0.45, -0.15, -0.049, 0.45, 0.45, 0.049}},
    tiles = {"default_wood_pale.png"},
    groups = {choppy=2, dig_immediate=2},
    drop = "default:sign_wall",

    on_construct = function(pos)
        construct_sign(pos)
    end,
    on_destruct = function(pos)
        destruct_sign(pos)
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        update_sign(pos, fields)
    end,
	on_punch = function(pos, node, puncher)
		update_sign(pos)
	end,
})

minetest.register_entity("signs:text", {
    collisionbox = { 0, 0, 0, 0, 0, 0 },
    visual = "upright_sprite",
    textures = {},

    on_activate = function(self)
        local meta = minetest.get_meta(self.object:getpos())
        local text = meta:get_string("text")
        self.object:set_properties({textures={generate_texture(create_lines(text))}})
    end
})

-- CONSTANTS
local SIGN_WITH = 180
local SIGN_PADDING = 0

local LINE_LENGTH = 14
local NUMBER_OF_LINES = 4

local LINE_HEIGHT = 24
local CHAR_WIDTH = 5

string_to_array = function(str)
	local tab = {}
	for i=1,string.len(str) do
		table.insert(tab, string.sub(str, i,i))
	end
	return tab
end

string_to_word_array = function(str)
	local tab = {}
	local current = 1
	tab[1] = ""
	for _,char in ipairs(string_to_array(str)) do
		if char ~= " " then
			tab[current] = tab[current]..char
		else
			current = current+1
			tab[current] = ""
		end
	end
	return tab
end

create_lines = function(text)
	local line = ""
	local line_num = 1
	local tab = {}
	for _,word in ipairs(string_to_word_array(text)) do
		if string.len(line)+string.len(word) < LINE_LENGTH and word ~= "|" then
			if line ~= "" then
				line = line.." "..word
			else
				line = word
			end
		else
			table.insert(tab, line)
			if word ~= "|" then
				line = word
			else
				line = ""
			end
			line_num = line_num+1
			if line_num > NUMBER_OF_LINES then
				return tab
			end
		end
	end
	table.insert(tab, line)
	return tab
end

generate_texture = function(lines)
    local texture = "[combine:"..SIGN_WITH.."x"..SIGN_WITH
    local ypos = 20
    if #lines < 3 then
	ypos = ypos + (4-#lines) * LINE_HEIGHT/2
    end
    for i = 1, #lines do
        texture = texture..generate_line(lines[i], ypos)
        ypos = ypos + LINE_HEIGHT
    end
    return texture
end

generate_line = function(s, ypos)
    local i = 1
    local parsed = {}
    local width = 0
    local chars = 0
    local clen
    local cltab = {}
    while chars < max_chars and i <= #s do
        local file = nil
        if charmap[s:sub(i, i)] ~= nil then
            file = charmap[s:sub(i, i)]
	    clen = charlen[s:sub(i, i)]
	    table.insert(cltab, clen)
            i = i + 1
        elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
            file = charmap[s:sub(i, i + 1)]
	    clen = charlen[s:sub(i, i)]
	    table.insert(cltab, clen)
            i = i + 2
        else
            print("[signs] W: unknown symbol in '"..s.."' at "..i.." (probably "..s:sub(i, i)..")")
            i = i + 1
        end
        if file ~= nil then
            width = width + 2*clen
            table.insert(parsed, file)
            chars = chars + 1
        end
    end
    width = width - 1

    local texture = ""
    local xpos = math.floor((SIGN_WITH - 2 * SIGN_PADDING - width) / 2 + SIGN_PADDING)
    for i = 1, #parsed do
        texture = texture..":"..xpos..","..ypos.."="..parsed[i]..".png"
        xpos = xpos + 2*cltab[i]
    end
    return texture
end

if minetest.setting_get("log_mods") then
	minetest.log("action", "signs loaded")
end
