local mod = get_mod("inventory_improved")

local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")
local WeaponStats = require("scripts/utilities/weapon_stats")

local NUM_DISPLAY_STATS = 5

local STAT_ICONS = {
	loc_stats_display_damage_stat = "content/ui/materials/icons/system/settings/dropdown/icon_crosshair_killshot",
	loc_stats_display_crit_stat = "content/ui/materials/icons/system/settings/dropdown/icon_crosshair_dot",
	loc_stats_display_first_target_stat = "content/ui/materials/icons/weapons/actions/smiter",
	loc_stats_display_ap_stat = "content/ui/materials/icons/weapons/actions/special_bullet",
	loc_stats_display_armor_pierce_stat = "content/ui/materials/icons/weapons/actions/special_bullet",
	loc_stats_display_finesse_stat = "content/ui/materials/icons/weapons/actions/ninjafencer",
	loc_stats_display_mobility_stat = "content/ui/materials/icons/pocketables/hud/small/party_syringe_speed",
	loc_stats_display_ammo_stat = "content/ui/materials/icons/player_states/ammo",
	loc_stats_display_stability_stat = "content/ui/materials/icons/weapons/actions/brace",
	loc_stats_display_reload_speed_stat = "content/ui/materials/icons/generic/hourglass",
	loc_stats_display_power_stat = "content/ui/materials/icons/weapons/actions/activate",
	loc_stats_display_power_output = "content/ui/materials/icons/weapons/actions/special_attack",
	loc_stats_display_charge_speed = "content/ui/materials/icons/weapons/actions/charge",
	loc_stats_display_range_stat = "content/ui/materials/icons/weapons/actions/ads",
	loc_stats_display_control_stat_melee = "content/ui/materials/icons/weapons/actions/linesman",
	loc_stats_display_control_stat_ranged = "content/ui/materials/icons/weapons/actions/linesman",
	loc_stats_display_defense_stat = "content/ui/materials/icons/weapons/actions/defence",
	loc_stats_display_defence_stat = "content/ui/materials/icons/weapons/actions/defence",
	loc_stats_display_cleave_damage_stat = "content/ui/materials/icons/weapons/actions/tank",
	loc_stats_display_cleave_targets_stat = "content/ui/materials/icons/weapons/actions/linesman",
	loc_stats_display_cleave_stat = "content/ui/materials/icons/weapons/actions/tank",
	loc_stats_display_cleave_damage_and_targets_stat = "content/ui/materials/icons/weapons/actions/linesman",
	loc_stats_display_vent_speed = "content/ui/materials/icons/weapons/actions/vent",
	loc_stats_display_heat = "content/ui/materials/icons/generic/danger",
	loc_stats_display_explosion_size_stat = "content/ui/materials/icons/weapons/actions/quick_grenade",
	loc_stats_display_burn_stat = "content/ui/materials/icons/generic/danger",
	loc_stats_display_flame_size_stat = "content/ui/materials/icons/generic/danger",
	loc_stats_display_arc_stat = "content/ui/materials/icons/weapons/actions/charge",
	loc_stats_display_warp_charge_cost_stat = "content/ui/materials/icons/weapons/actions/activate",
}

local DEFAULT_STAT_ICON = "content/ui/materials/icons/objectives/secondary"

local STAT_ABBREVIATIONS = {
	loc_stats_display_damage_stat = "DMG",
	loc_stats_display_crit_stat = "CRIT",
	loc_stats_display_first_target_stat = "FT",
	loc_stats_display_ap_stat = "AP",
	loc_stats_display_armor_pierce_stat = "AP",
	loc_stats_display_finesse_stat = "FIN",
	loc_stats_display_mobility_stat = "MOB",
	loc_stats_display_ammo_stat = "AMMO",
	loc_stats_display_stability_stat = "STAB",
	loc_stats_display_reload_speed_stat = "RLD",
	loc_stats_display_power_stat = "PWR",
	loc_stats_display_power_output = "PWR",
	loc_stats_display_charge_speed = "CHG",
	loc_stats_display_range_stat = "RNG",
	loc_stats_display_control_stat_melee = "CTRL",
	loc_stats_display_control_stat_ranged = "CTRL",
	loc_stats_display_defense_stat = "DEF",
	loc_stats_display_defence_stat = "DEF",
	loc_stats_display_cleave_damage_stat = "CLV",
	loc_stats_display_cleave_targets_stat = "CLV",
	loc_stats_display_cleave_stat = "CLV",
	loc_stats_display_cleave_damage_and_targets_stat = "CLV",
	loc_stats_display_vent_speed = "VENT",
	loc_stats_display_heat = "HEAT",
	loc_stats_display_explosion_size_stat = "EXP",
	loc_stats_display_burn_stat = "BRN",
	loc_stats_display_flame_size_stat = "FLM",
	loc_stats_display_arc_stat = "ARC",
	loc_stats_display_warp_charge_cost_stat = "WRP",
}

local cache = {}
local cache_count = 0
local CACHE_LIMIT = 512

local ItemStats = {}

ItemStats.num_display_stats = NUM_DISPLAY_STATS
ItemStats.default_icon = DEFAULT_STAT_ICON

ItemStats.clear_cache = function()
	table.clear(cache)
	cache_count = 0
end

local function get_comparing_stats(item)
	local ok, comparing = pcall(function()
		local stub = setmetatable({
			_item = item,
		}, {
			__index = WeaponStats,
		})

		return stub:get_comparing_stats()
	end)

	if ok and comparing and #comparing > 0 then
		return comparing
	end

	local ok_init, weapon_stats = pcall(WeaponStats.new, WeaponStats, item)

	if ok_init and weapon_stats then
		local ok_compare, compared = pcall(function()
			return weapon_stats:get_comparing_stats()
		end)

		if ok_compare and compared and #compared > 0 then
			return compared
		end
	end

	return nil
end

local function stat_entry(name, display_name, fraction)
	return {
		name = name,
		display_name = display_name,
		abbreviation = STAT_ABBREVIATIONS[display_name],
		icon = STAT_ICONS[display_name] or DEFAULT_STAT_ICON,
		percentage = math.floor(fraction * 100 + 0.5),
	}
end

ItemStats.get_display_stats = function(item)
	if not item then
		return nil
	end

	local base_stats = item.base_stats

	if not base_stats or #base_stats == 0 then
		return nil
	end

	local cache_key = item.gear_id
	local cached = cache_key and cache[cache_key]

	if cached then
		return cached
	end

	local stats = {}
	local comparing = get_comparing_stats(item)

	if comparing then
		for i = 1, #comparing do
			local stat = comparing[i]

			if stat.display_name then
				stats[#stats + 1] = stat_entry(stat.name, stat.display_name, stat.fraction)
			end
		end
	else
		local weapon_template = WeaponTemplate.weapon_template_from_item(item)
		local template_stats = weapon_template and weapon_template.base_stats

		if not template_stats then
			return nil
		end

		for i = 1, #base_stats do
			local base_stat = base_stats[i]
			local stat_definition = template_stats[base_stat.name]

			if stat_definition then
				stats[#stats + 1] = stat_entry(base_stat.name, stat_definition.display_name, base_stat.value)
			end
		end
	end

	if #stats == 0 then
		return nil
	end

	if cache_key then
		if cache_count >= CACHE_LIMIT then
			table.clear(cache)
			cache_count = 0
		end

		cache[cache_key] = stats
		cache_count = cache_count + 1
	end

	return stats
end

return ItemStats
