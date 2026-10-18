local mod = get_mod("inventory_improved")
mod.version = "1.5.0"

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function utf8_chars(s)
	local chars = {}
	for char in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(chars, char)
	end
	return chars
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local chars = utf8_chars(text)
	local visibleIndex = 0

	for _, char in ipairs(chars) do
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for _, char in ipairs(chars) do
		if not colorSpaces and char == " " then
			result = result .. char
		else
			currentIndex = currentIndex + 1
			local t = (visibleIndex <= 1) and 0 or (currentIndex - 1) / (visibleIndex - 1)

			local r = math.floor(lerp(startColor[1], endColor[1], t))
			local g = math.floor(lerp(startColor[2], endColor[2], t))
			local b = math.floor(lerp(startColor[3], endColor[3], t))

			result = result .. string.format("{#color(%d,%d,%d)}%s", r, g, b, char)
		end
	end

	result = "{#color(" .. colours.title .. ")}" .. result .. "{#reset()}"
	return result
end

local mod_name = {
	en = "Inventory Improved",
}
mod:info(mod_name["en"] .. " is installed, using version: " .. tostring(mod.version))

mod.localisation = {

	mod_name = {
		en = mod_name["en"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 255, 140, 0 }, { 255, 255, 0 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
	},

	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "Adds configurable item grid styles and an in-game settings overlay to the inventory screen."
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Author: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Version: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
	},

	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
		ru = "Включить красочные имена",
		["zh-cn"] = "启用名称特效",
		["zh-tw"] = "啟用名稱特效",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужный эффект для текста имени мода. Требуется перезагрузка.\nЕсли включено, вы будете получать небольшой эйфорический опыт каждый раз, когда прокручиваете меню модов.\nЕсли выключено - вы будете Джоном Дарктайдом и без радужных посыпок (но я все равно буду вас любить).",
		["zh-cn"] = "切换模组名称的彩虹颜色效果。需要重新加载。\n启用后，每次滚动模组菜单时你都会获得小小的愉悦体验。\n禁用后，你将失去彩虹点缀（但我仍然爱你）。",
		["zh-tw"] = "切換模組名稱的彩虹顏色效果。需要重新載入。\n啟用後，每次滾動模組選單時你都會獲得小小的愉悅體驗。\n停用後，你將成為一般的黑暗潮汐玩家，失去彩虹點綴（但我仍然愛你）。",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}通用设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}一般設定{#reset()}",
	},

	item_grid_settings = {
		en = "{#color(" .. colours.title .. ")}Item Grid{#reset()}",
	},
	items_per_row = {
		en = "Items Per Row",
	},
	items_per_row_tooltip = {
		en = "Number of item cards shown per row in the inventory item list.\n1 = classic wide list. Higher values show compact item cards, multiple per row.\nCard width is calculated from this value; card height is set separately.\nChanges apply immediately.",
	},
	compact_card_height = {
		en = "Compact Card Height",
	},
	compact_card_height_tooltip = {
		en = "Fixed height of the compact item cards, in pixels. Width is always derived from Items Per Row.\nName, rank and rarity details scale with the height. Changes apply immediately.",
	},
	show_item_stats = {
		en = "Show Stats On Cards",
	},
	show_item_stats_tooltip = {
		en = "Shows each weapon stat along the bottom of compact item cards, laid out in an aligned grid.\nRequires enough card width to fit the stats; the strip hides automatically when there is not enough room.\nChanges apply immediately.",
	},
	show_stat_abbreviations = {
		en = "Stat Name Abbreviations",
	},
	show_stat_abbreviations_tooltip = {
		en = "Shows a short abbreviation before each stat value, e.g. Damage becomes DMG.\nWhen disabled, only the percentage is shown.\nChanges apply immediately.",
	},

	interface_settings = {
		en = "{#color(" .. colours.title .. ")}Interface{#reset()}",
	},
	show_settings_button = {
		en = "Show Settings Button",
	},
	show_settings_button_tooltip = {
		en = "Shows or hides the settings button on the inventory screen.",
	},
	settings_button_text = {
		en = "SETTINGS",
	},
	settings_overlay_title = {
		en = "Inventory Improved",
	},
}

mod:add_global_localize_strings({

	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
		ru = "Включить красочные имена",
		["zh-cn"] = "启用名称特效",
		["zh-tw"] = "啟用名稱特效",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужный эффект для текста имени мода. Требуется перезагрузка.\nЕсли включено, вы будете получать небольшой эйфорический опыт каждый раз, когда прокручиваете меню модов.\nЕсли выключено - вы будете Джоном Дарктайдом и без радужных посыпок (но я все равно буду вас любить).",
		["zh-cn"] = "切换模组名称的彩虹颜色效果。需要重新加载。\n启用后，每次滚动模组菜单时你都会获得小小的愉悦体验。\n禁用后，你将失去彩虹点缀（但我仍然爱你）。",
		["zh-tw"] = "切換模組名稱的彩虹顏色效果。需要重新載入。\n啟用後，每次滾動模組選單時你都會獲得小小的愉悅體驗。\n停用後，你將成為一般的黑暗潮汐玩家，失去彩虹點綴（但我仍然愛你）。",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}通用设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}一般設定{#reset()}",
	},

	item_grid_settings = {
		en = "{#color(" .. colours.title .. ")}Item Grid{#reset()}",
	},
	items_per_row = {
		en = "Items Per Row",
	},
	items_per_row_tooltip = {
		en = "Number of item cards shown per row in the inventory item list.\n1 = classic wide list. Higher values show compact item cards, multiple per row.\nCard width is calculated from this value; card height is set separately.\nChanges apply immediately.",
	},
	compact_card_height = {
		en = "Compact Card Height",
	},
	compact_card_height_tooltip = {
		en = "Fixed height of the compact item cards, in pixels. Width is always derived from Items Per Row.\nName, rank and rarity details scale with the height. Changes apply immediately.",
	},
	show_item_stats = {
		en = "Show Stats On Cards",
	},
	show_item_stats_tooltip = {
		en = "Shows each weapon stat along the bottom of compact item cards, laid out in an aligned grid.\nRequires enough card width to fit the stats; the strip hides automatically when there is not enough room.\nChanges apply immediately.",
	},
	show_stat_abbreviations = {
		en = "Stat Name Abbreviations",
	},
	show_stat_abbreviations_tooltip = {
		en = "Shows a short abbreviation before each stat value, e.g. Damage becomes DMG.\nWhen disabled, only the percentage is shown.\nChanges apply immediately.",
	},

	interface_settings = {
		en = "{#color(" .. colours.title .. ")}Interface{#reset()}",
	},
	show_settings_button = {
		en = "Show Settings Button",
	},
	show_settings_button_tooltip = {
		en = "Shows or hides the settings button on the inventory screen.",
	},
	settings_button_text = {
		en = "SETTINGS",
	},
	settings_overlay_title = {
		en = "Inventory Improved",
	},
})

mod.toggle_pizazz = function()
	for key, values in pairs(mod.localisation) do
		if key == "mod_name" then
			for language, text in pairs(values) do
				if mod:get("mod_name_pizazz_toggle") then
					mod.localisation[key][language] = mod.localisation["mod_name_pizazz"][language]
				else
					mod.localisation[key][language] = mod.localisation["mod_name_boring"][language]
				end
			end
		end
	end
end

mod.toggle_pizazz()

return mod.localisation
