lava_ore_gen = {blacklist = {}}
local interval = tonumber(minetest.settings:get("lava_ore_gen.interval")) or 3600
local chance = tonumber(minetest.settings:get("lava_ore_gen.chance")) or 86400
local random_setting = minetest.settings:get_bool("lava_ore_gen.random") or false
local set_node = minetest.set_node
local sound_play = minetest.sound_play
local find_node_near = minetest.find_node_near
local registered_ores = minetest.registered_ores
local get_node_timer = minetest.get_node_timer
local match = string.match
local random = math.random
local hot_stone = {}

hot_stone.name = "lava_ore_gen:stone_hot"
hot_stone.description = "Heated Stone"
hot_stone.groups = {
	not_in_creative_inventory = 1
}
hot_stone.paramtype = "light"
hot_stone.light_source = 4
hot_stone.on_timer = function(pos)
	local node = find_node_near(pos, 1, {"group:lava"})
	if not node then
		set_node(pos, {name = "default:stone"})
		return false
	end
	if not random_setting then
		-- Get ores and rarities.
		local ore_map = {}
		for i, v in next, registered_ores do
			local name = v.ore
			if not lava_ore_gen.blacklist[name] then
				if match(name, ":stone_with_") or match(name, ":mineral_") then
					local rarity = v.clust_scarcity - random(0, v.clust_scarcity + 1)
					ore_map[i] = {rarity = rarity, name = name}
				end
			end
		end
		-- Do math to pick a ore.
		local ore = {rarity = -1, name = "default:stone"}
		for i, v in next, ore_map do
			if ore.rarity == -1 or ore.rarity > random(0, v.rarity) then
				ore = v
			end
		end
		set_node(pos, {name = ore.name})
	else
		local ore_map = {}
		for i, v in next, registered_ores do
			local name = v.ore
			if not lava_ore_gen.blacklist[name] then
				ore_map[#ore_map + 1] = name
			end
		end
		set_node(pos, {name = ore_map[random(1, #ore_map + 1)]})
	end
end
for k, v in pairs(minetest.registered_nodes["default:stone"]) do 
	if not hot_stone[k] then
		hot_stone[k] = v
	elseif type(v) == "table" then
		for i, j in pairs(v) do
			hot_stone[k][i] = j
		end
	end
end
hot_stone.tiles = {"default_stone.png^[colorize:red:20"}
minetest.register_node("lava_ore_gen:stone_hot", hot_stone)

default.cool_lava = function(pos, node)
	if node.name == "default:lava_source" then
		set_node(pos, {name = "default:obsidian"})
	else -- Lava flowing
		set_node(pos, {name = "lava_ore_gen:stone_hot"})
		get_node_timer(pos):start(interval + random(1, chance + 1))
	end
	sound_play("default_cool_lava",
		{pos = pos, max_hear_distance = 16, gain = 0.25}, true)
end

minetest.register_lbm({
	label = "Make hot stone",
	name = "lava_ore_gen:make_hot_stone",
	nodenames = {"default:stone"},
	run_at_every_load = true,
	action = function(pos, node)
		local lava_near = find_node_near(pos, 1, {"group:lava"})

		if lava_near then
			set_node(pos, {name = "lava_ore_gen:stone_hot"})
			get_node_timer(pos):start(interval + random(1, chance + 1))
		end
	end
})

if minetest.settings:get_bool("log_mods") then
	minetest.log("action", "[Lava Ore Generation] Loaded.")
end