-- Weather:
-- * rain
-- * snow
-- * wind (not implemented)

assert(minetest.add_particlespawner, "I told you to run the latest GitHub!")

addvectors = function (v1, v2)
	return {x=v1.x+v2.x, y=v1.y+v2.y, z=v1.z+v2.z}
end

save_weather = function ()
	local file = io.open(minetest.get_worldpath().."/weather", "w+")
	file:write(weather)
	file:close()
end

read_weather = function ()
	local file = io.open(minetest.get_worldpath().."/weather", "r")
	if not file then return end
	local readweather = file:read()
	file:close()
	return readweather
end

set_sky = function()
	if weather == "rain" or weather == "snow" then
		local time = minetest.get_timeofday()
		local color
		if time > 0.25 and time < 0.75 then
			color = {r=100, g=100, b=100}
		else
			color = {r=30, g=30, b=30}
		end
		for _, player in ipairs(minetest.get_connected_players()) do
			player:set_sky(color, "plain")
		end
	else
		for _, player in ipairs(minetest.get_connected_players()) do
			player:set_sky(nil, "regular")
		end
	end
	if weather == "rain" and math.random() < .001 then
		for _, player in ipairs(minetest.get_connected_players()) do
			local ppos = player:getpos()
			if ppos.y > -50 then
				player:set_sky({r=255, g=255, b=255}, "plain")
				minetest.sound_play("thunder")
			end
		end
	end
end

weather = read_weather()
minetest.register_globalstep(function(dtime)
	set_sky()
end)

minetest.register_globalstep(function(dtime)
	if weather == "rain" or weather == "snow" then
		local time = minetest.get_timeofday()
		if (time >= 0.23 and time <= 0.24) or math.random(1, 10000) == 1 then
			weather = "none"
			save_weather()
		end
	else
		if math.random(1, 30000) == 2 then
			weather = "rain"
			save_weather()
		end
		if math.random(1, 60000) == 2 then
			weather = "snow"
			save_weather()
		end
	end
end)

dofile(minetest.get_modpath("weather").."/rain.lua")
dofile(minetest.get_modpath("weather").."/snow.lua")
dofile(minetest.get_modpath("weather").."/command.lua")


