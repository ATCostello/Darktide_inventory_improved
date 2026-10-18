local mod = get_mod("inventory_improved")

local Items = require("scripts/utilities/items")
local UISettings = require("scripts/settings/ui/ui_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local Colors = require("scripts/utilities/ui/colors")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

local ItemText = mod.item_text
local ItemStats = mod.item_stats

local WEAPON_ICON_SIZE = UISettings.weapon_icon_size

local COMPACT_WIDGET_TYPE = "inventory_improved_compact"

mod.COMPACT_WIDGET_TYPE = COMPACT_WIDGET_TYPE

local FAVORITE_GLYPH = string.char(0xEE, 0x81, 0x86)

local CARD_PADDING = 6
local RARITY_BAR_WIDTH = 5
local ICON_MAX_WIDTH_FRACTION = 0.42
local SUB_NAME_MIN_HEIGHT = 56
local RARITY_NAME_MIN_WIDTH = 280
local FAVORITE_TEXT_MIN_WIDTH = 300
local STATS_CELL_MIN_WIDTH = 44
local STATS_ROW_CELL_MIN_WIDTH = 38
local NUM_STATS = ItemStats and ItemStats.num_display_stats or 5

local STAT_ABBR_FONT = UIFontSettings.body_small.font_type
local STAT_VALUE_FONT = "proxima_nova_medium"
local STAT_ABBR_COLOR = Color.terminal_text_header(255, true)
local STAT_VALUE_COLOR = Color.terminal_text_body(255, true)

local function clamp_font_size(value, min_size, max_size)
	return math.max(min_size, math.min(max_size, value))
end

local function favorite_label(layout)
	return layout.show_favorite_text
			and string.format("%s %s", FAVORITE_GLYPH, Localize("loc_inventory_menu_favorite_item"))
		or FAVORITE_GLYPH
end

local function hotspot_anim_progress(hotspot)
	return math.max(
		math.max(hotspot.anim_hover_progress or 0, hotspot.anim_select_progress or 0),
		hotspot.anim_focus_progress or 0
	)
end

local function item_change_function(content, style)
	local hotspot = content.hotspot
	local is_selected = hotspot.is_selected
	local is_focused = hotspot.is_focused
	local is_hover = hotspot.is_hover
	local default_color = style.default_color
	local selected_color = style.selected_color
	local hover_color = style.hover_color
	local color

	if is_selected or is_focused then
		color = selected_color
	elseif is_hover then
		color = hover_color
	else
		color = default_color
	end

	Colors.color_lerp(style.color, color, hotspot_anim_progress(hotspot), style.color)
end

local function text_hover_change_function(content, style)
	local progress = hotspot_anim_progress(content.hotspot)

	Colors.color_lerp(style.default_color, style.hover_color, progress, style.text_color)
end

local function apply_live_item_icon(widget, grid_index, rows, columns, render_target)
	local material_values = widget.style.icon.material_values

	material_values.use_placeholder_texture = 0
	material_values.use_render_target = 1
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = grid_index - 1
	material_values.render_target = render_target
	widget.content.use_placeholder_texture = material_values.use_placeholder_texture
end

local function remove_live_item_icon(widget, ui_renderer)
	UIWidget.set_visible(widget, ui_renderer, false)

	local material_values = widget.style.icon.material_values

	material_values.use_placeholder_texture = 1
	material_values.render_target = nil
	widget.content.use_placeholder_texture = material_values.use_placeholder_texture
end

local function is_item_equipped_in_any_slot(view_instance, item, slots)
	if not view_instance or not view_instance.equipped_item_in_slot or not slots or not item.gear_id then
		return false
	end

	for i = 1, #slots do
		local equipped_item = view_instance:equipped_item_in_slot(slots[i])

		if equipped_item and equipped_item.gear_id == item.gear_id then
			return true
		end
	end

	return false
end

local function is_item_equipped_in_slot(view_instance, item, slot_name)
	if not view_instance or not view_instance.equipped_item_in_slot or not item.gear_id then
		return false
	end

	local equipped_item = view_instance:equipped_item_in_slot(slot_name)

	return equipped_item ~= nil and equipped_item.gear_id == item.gear_id
end

local function compute_stats_rows(region_width, height, name_font, stats_row_height)
	local single_cell = region_width / NUM_STATS

	if single_cell >= STATS_CELL_MIN_WIDTH then
		return 1, single_cell
	end

	local two_cell = region_width / 3
	local two_y_b = height - stats_row_height - 2
	local two_y_a = two_y_b - stats_row_height - 2

	if two_cell >= STATS_ROW_CELL_MIN_WIDTH and two_y_a >= name_font + 6 then
		return 2, two_cell
	end

	return 0, 0
end

local function compute_layout(width, height, stats_enabled)
	local icon_aspect = WEAPON_ICON_SIZE[1] / WEAPON_ICON_SIZE[2]
	local max_icon_width = math.floor(width * ICON_MAX_WIDTH_FRACTION)
	local icon_height = height - 8
	local icon_width = math.floor(icon_height * icon_aspect)

	if icon_width > max_icon_width then
		icon_width = max_icon_width
		icon_height = math.floor(icon_width / icon_aspect)
	end

	local icon_x = width - icon_width - 3
	local icon_y = math.floor((height - icon_height) * 0.5)
	local text_x = RARITY_BAR_WIDTH + CARD_PADDING
	local text_width = math.max(width - text_x - icon_width - 8, 32)
	local name_font = clamp_font_size(math.floor(height * 0.24), 13, 20)
	local sub_font = clamp_font_size(math.floor(height * 0.22), 13, 20)
	local rarity_font = clamp_font_size(math.floor(height * 0.2), 12, 18)
	local level_font = clamp_font_size(math.floor(height * 0.22), 12, 18)
	local equipped_size = math.max(18, math.floor(height * 0.35))
	local stats_icon = clamp_font_size(math.floor(height * 0.18), 12, 18)
	local stats_font = clamp_font_size(math.floor(height * 0.15), 10, 14)
	local stats_row_height = stats_icon + 4
	local stats_cell = 0
	local stats_rows = 0
	local show_icon = true

	if stats_enabled then
		stats_rows, stats_cell = compute_stats_rows(text_width, height, name_font, stats_row_height)

		if stats_rows == 0 then
			local full_text_width = math.max(width - text_x - 8, 32)
			local full_rows, full_cell = compute_stats_rows(full_text_width, height, name_font, stats_row_height)

			if full_rows > 0 then
				show_icon = false
				icon_width = 0
				icon_height = 0
				text_width = full_text_width
				stats_rows = full_rows
				stats_cell = full_cell
			end
		end
	end

	local stats_row_visible = stats_rows > 0
	local stats_block_height =
		stats_row_visible and (stats_rows * stats_row_height + (stats_rows - 1) * 2) or 0
	local stats_y_b = stats_row_visible and height - stats_row_height - 2 or 0
	local stats_y = stats_row_visible
			and (stats_rows == 2 and stats_y_b - stats_row_height - 2 or stats_y_b)
		or 0
	local bottom_limit = height - (stats_row_visible and (stats_block_height + 2) or 0) - 2
	local sub_y = name_font + 6
	local sub_h = sub_font + 6
	local rarity_y = name_font + sub_font + 9
	local rarity_h = rarity_font + 4
	local show_sub_name = not stats_row_visible and height >= SUB_NAME_MIN_HEIGHT and (sub_y + sub_h) <= bottom_limit
	local rarity_draw_y = show_sub_name and rarity_y or sub_y
	local show_rarity_name = width >= RARITY_NAME_MIN_WIDTH and (rarity_draw_y + rarity_h) <= bottom_limit

	return {
		width = width,
		height = height,
		icon_width = icon_width,
		icon_height = icon_height,
		icon_x = icon_x,
		icon_y = icon_y,
		show_icon = show_icon,
		text_x = text_x,
		text_width = text_width,
		name_font = name_font,
		sub_font = sub_font,
		level_font = level_font,
		rarity_font = rarity_font,
		equipped_size = equipped_size,
		favorite_font = clamp_font_size(math.floor(height * 0.22), 13, 18),
		stats_icon = stats_icon,
		stats_font = stats_font,
		stats_row_height = stats_row_height,
		stats_block_height = stats_block_height,
		stats_rows = stats_rows,
		stats_cell = stats_cell,
		stats_x = text_x,
		stats_y = stats_y,
		stats_y_b = stats_y_b,
		stats_row_visible = stats_row_visible,
		sub_y = sub_y,
		rarity_y = rarity_y,
		rarity_h = rarity_h,
		show_sub_name = show_sub_name,
		show_rarity_name = show_rarity_name,
		show_favorite_text = width >= FAVORITE_TEXT_MIN_WIDTH,
	}
end

local function append_stat_passes(passes, layout)
	local stats_font = layout.stats_font
	local stats_cell = layout.stats_cell
	local stats_rows = layout.stats_rows
	local stats_y = layout.stats_y
	local stats_y_b = layout.stats_y_b
	local stats_x = layout.stats_x
	local stats_row_height = layout.stats_row_height
	local split_index = stats_rows == 2 and 3 or NUM_STATS

	for i = 1, NUM_STATS do
		local row_b = i > split_index
		local row_y = row_b and stats_y_b or stats_y
		local column = (row_b and (i - split_index) or i) - 1
		local cell_x = stats_x + column * stats_cell
		local cell_center = cell_x + stats_cell * 0.5

		passes[#passes + 1] = {
			pass_type = "text",
			style_id = "stat_abbr_" .. i,
			value = "",
			value_id = "stat_abbr_" .. i,
			style = {
				font_type = STAT_ABBR_FONT,
				font_size = stats_font,
				text_horizontal_alignment = "right",
				text_vertical_alignment = "center",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				text_color = STAT_ABBR_COLOR,
				size = {
					stats_cell,
					stats_row_height,
				},
				offset = {
					cell_center - stats_cell,
					row_y,
					10,
				},
			},
			visibility_function = function(content)
				return (content.stats_visible and content["has_stat_" .. i] and content["has_abbr_" .. i]) or false
			end,
		}

		passes[#passes + 1] = {
			pass_type = "text",
			style_id = "stat_value_" .. i,
			value = "",
			value_id = "stat_value_" .. i,
			style = {
				font_type = STAT_VALUE_FONT,
				font_size = stats_font,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "center",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				text_color = STAT_VALUE_COLOR,
				size = {
					stats_cell,
					stats_row_height,
				},
				offset = {
					cell_center,
					row_y,
					10,
				},
			},
			visibility_function = function(content)
				return (content.stats_visible and content["has_stat_" .. i]) or false
			end,
			change_function = function(content, style)
				if content["has_abbr_" .. i] then
					style.text_horizontal_alignment = "left"
					style.offset[1] = cell_center
				else
					style.text_horizontal_alignment = "center"
					style.offset[1] = cell_x
				end
			end,
		}
	end
end

local function create_pass_template(layout)
	local width = layout.width
	local height = layout.height
	local name_font = layout.name_font
	local sub_font = layout.sub_font
	local rarity_font = layout.rarity_font
	local level_font = layout.level_font
	local equipped_size = layout.equipped_size
	local band_height = math.floor(height * 0.36)
	local indicator_size = math.max(40, math.floor(height * 0.9))
	local loading_size = math.max(24, math.floor(layout.icon_height * 0.6))
	local check_size = math.max(24, math.floor(height * 0.55))

	local passes = {
		{
			pass_type = "texture",
			style_id = "outer_shadow",
			value = "content/ui/materials/frames/dropshadow_medium",
			style = {
				color = Color.black(200, true),
				horizontal_alignment = "center",
				vertical_alignment = "center",
				scale_to_material = true,
				size_addition = {
					20,
					20,
				},
			},
		},
		{
			content_id = "hotspot",
			pass_type = "hotspot",
			style_id = "hotspot",
			style = {
				on_hover_sound = UISoundEvents.default_mouse_hover,
				on_pressed_sound = UISoundEvents.default_click,
			},
		},
		{
			pass_type = "texture",
			style_id = "background",
			value = "content/ui/materials/backgrounds/default_square",
			style = {
				color = Color.terminal_background_dark(nil, true),
				selected_color = Color.terminal_background_selected(nil, true),
			},
		},
		{
			pass_type = "texture_uv",
			style_id = "background_gradient",
			value = "content/ui/materials/gradients/gradient_diagonal_down_right",
			style = {
				color = Color.terminal_background_gradient(nil, true),
				default_color = Color.terminal_background_gradient(nil, true),
				horizontal_alignment = "left",
				vertical_alignment = "center",
				offset = {
					0,
					0,
					2,
				},
				uvs = {
					{
						1,
						0,
					},
					{
						0,
						1,
					},
				},
			},
			change_function = function(content, style)
				style.color[1] = 150
			end,
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/patterns/diagonal_lines_pattern_01",
			style = {
				color = {
					105,
					45,
					45,
					45,
				},
				vertical_alignment = "top",
				offset = {
					0,
					0,
					2,
				},
			},
			visibility_function = function(content)
				return not content.level_requirement_met
			end,
		},
		{
			pass_type = "texture",
			style_id = "button_gradient",
			value = "content/ui/materials/gradients/gradient_diagonal_down_right",
			style = {
				default_color = Color.terminal_background_gradient(nil, true),
				selected_color = Color.terminal_frame_selected(nil, true),
				horizontal_alignment = "center",
				vertical_alignment = "center",
				offset = {
					0,
					0,
					1,
				},
			},
			change_function = function(content, style)
				ButtonPassTemplates.terminal_button_change_function(content, style)
				ButtonPassTemplates.terminal_button_hover_change_function(content, style)
			end,
		},
		{
			pass_type = "texture",
			style_id = "inner_shadow",
			value = "content/ui/materials/frames/inner_shadow_medium",
			style = {
				color = Color.black(100, true),
				horizontal_alignment = "center",
				vertical_alignment = "top",
				scale_to_material = true,
				size = {
					width,
					height,
				},
				offset = {
					0,
					0,
					3,
				},
			},
		},
		{
			pass_type = "texture",
			style_id = "inner_highlight",
			value = "content/ui/materials/frames/inner_shadow_medium",
			style = {
				color = Color.terminal_background_gradient_selected(255, true),
				horizontal_alignment = "center",
				vertical_alignment = "top",
				scale_to_material = true,
				size = {
					width,
					height,
				},
				offset = {
					0,
					0,
					4,
				},
			},
			change_function = function(content, style)
				local hotspot = content.hotspot

				style.color[1] = math.max(hotspot.anim_focus_progress or 0, hotspot.anim_select_progress or 0) * 255
			end,
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/symbols/new_item_indicator",
			style = {
				color = Color.terminal_corner_selected(255, true),
				horizontal_alignment = "right",
				vertical_alignment = "top",
				size = {
					indicator_size,
					indicator_size,
				},
				offset = {
					math.floor(height * 0.25),
					-math.floor(height * 0.25),
					5,
				},
			},
			visibility_function = function(content)
				local element = content.element

				return element ~= nil and element.new_item_marker or false
			end,
			change_function = function(content, style)
				local anim_progress = 1 - (0.5 + math.sin(Application.time_since_launch() * 5) * 0.5)
				local hotspot = content.hotspot

				style.color[1] = 150 + anim_progress * 80

				if hotspot.is_selected or hotspot.on_hover_exit then
					local element = content.element

					element.new_item_marker = nil

					local item = element.real_item or element.item

					if element.remove_new_marker_callback and item then
						element.remove_new_marker_callback(item)
					end
				end
			end,
		},
		{
			pass_type = "texture",
			style_id = "icon",
			value = "content/ui/materials/icons/items/containers/item_container_landscape",
			value_id = "icon",
			style = {
				horizontal_alignment = "left",
				vertical_alignment = "top",
				material_values = {},
				size = {
					layout.icon_width,
					layout.icon_height,
				},
				offset = {
					layout.icon_x,
					layout.icon_y,
					4,
				},
			},
			visibility_function = function(content)
				return layout.show_icon and content.use_placeholder_texture == 0
			end,
		},
		{
			pass_type = "rotated_texture",
			style_id = "loading",
			value = "content/ui/materials/loading/loading_small",
			style = {
				angle = 0,
				color = {
					60,
					160,
					160,
					160,
				},
				horizontal_alignment = "left",
				vertical_alignment = "top",
				size = {
					loading_size,
					loading_size,
				},
				offset = {
					layout.icon_x + math.floor((layout.icon_width - loading_size) * 0.5),
					layout.icon_y + math.floor((layout.icon_height - loading_size) * 0.5),
					4,
				},
			},
			visibility_function = function(content)
				local use_placeholder_texture = content.use_placeholder_texture

				return layout.show_icon and (not use_placeholder_texture or use_placeholder_texture == 1)
			end,
			change_function = function(content, style, _, dt)
				style.rotation_progress = ((style.rotation_progress or 0) - 0.5 * (dt or 0)) % 1
				style.angle = style.rotation_progress * math.pi * 2
			end,
		},
		{
			pass_type = "text",
			style_id = "display_name",
			value = "n/a",
			value_id = "display_name",
			style = {
				font_type = UIFontSettings.header_3.font_type,
				font_size = name_font,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				text_color = Color.terminal_text_header(255, true),
				default_color = Color.terminal_text_header(255, true),
				hover_color = Color.terminal_text_header_selected(255, true),
				size = {
					layout.text_width,
					name_font + 8,
				},
				offset = {
					layout.text_x,
					4,
					5,
				},
			},
			change_function = function(content, style)
				text_hover_change_function(content, style)

				local indent = content.equipped and (equipped_size + 4) or 0

				style.offset[1] = layout.text_x + indent
				style.size[1] = layout.text_width - indent
			end,
		},
	}

	if layout.show_sub_name then
		passes[#passes + 1] = {
			pass_type = "text",
			style_id = "sub_display_name",
			value = "n/a",
			value_id = "sub_display_name",
			style = {
				font_type = UIFontSettings.body_small.font_type,
				font_size = sub_font,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				text_color = Color.terminal_text_body_sub_header(255, true),
				default_color = Color.terminal_text_body_sub_header(255, true),
				hover_color = Color.terminal_text_body(255, true),
				size = {
					layout.text_width,
					sub_font + 6,
				},
				offset = {
					layout.text_x,
					name_font + 6,
					5,
				},
			},
			change_function = text_hover_change_function,
		}
	end

	if layout.show_rarity_name then
		passes[#passes + 1] = {
			pass_type = "text",
			style_id = "rarity_name",
			value = "n/a",
			value_id = "rarity_name",
			style = {
				font_type = UIFontSettings.body_small.font_type,
				font_size = rarity_font,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				text_color = Color.terminal_text_body_sub_header(255, true),
				size = {
					layout.text_width,
					layout.rarity_h,
				},
				offset = {
					layout.text_x,
					layout.show_sub_name and layout.rarity_y or layout.sub_y,
					5,
				},
			},
		}
	end

	passes[#passes + 1] = {
		pass_type = "text",
		style_id = "item_level",
		value = "n/a",
		value_id = "item_level",
		style = {
			font_type = UIFontSettings.body_small.font_type,
			font_size = level_font,
			text_horizontal_alignment = "right",
			text_vertical_alignment = "top",
			horizontal_alignment = "right",
			vertical_alignment = "top",
			text_color = Color.white(255, true),
			default_color = Color.white(255, true),
			hover_color = Color.white(255, true),
			material = "content/ui/materials/font_gradients/slug_font_gradient_item_level",
			size = {
				width,
				name_font + 8,
			},
			offset = {
				-6,
				4,
				5,
			},
		},
		change_function = function(content, style)
			local favorite_width = content.favorite and ((content.favorite_width or layout.favorite_font) + 6) or 0

			style.offset = {
				-(6 + favorite_width),
				4,
				5,
			}
		end,
	}

	if layout.stats_row_visible then
		append_stat_passes(passes, layout)
	end

	passes[#passes + 1] = {
		pass_type = "rect",
		style = {
			color = {
				150,
				0,
				0,
				0,
			},
			vertical_alignment = "top",
			offset = {
				0,
				0,
				6,
			},
		},
		visibility_function = function(content)
			return not content.level_requirement_met
		end,
	}

	passes[#passes + 1] = {
		pass_type = "rect",
		style_id = "required_level_background",
		style = {
			color = {
				150,
				35,
				0,
				0,
			},
			horizontal_alignment = "center",
			vertical_alignment = "top",
			size = {
				nil,
				band_height,
			},
			offset = {
				0,
				math.floor((height - band_height) * 0.5),
				7,
			},
		},
		visibility_function = function(content)
			return not content.level_requirement_met
		end,
	}

	passes[#passes + 1] = {
		pass_type = "text",
		style_id = "required_level",
		value = "loc_requires_level",
		value_id = "required_level",
		style = {
			font_type = UIFontSettings.header_3.font_type,
			font_size = clamp_font_size(math.floor(height * 0.24), 14, 22),
			text_horizontal_alignment = "center",
			text_vertical_alignment = "center",
			horizontal_alignment = "center",
			vertical_alignment = "center",
			text_color = {
				255,
				159,
				67,
				67,
			},
			size = {
				nil,
				band_height,
			},
			offset = {
				0,
				0,
				8,
			},
		},
		visibility_function = function(content)
			return not content.level_requirement_met
		end,
	}

	passes[#passes + 1] = {
		pass_type = "texture",
		style_id = "rarity_tag",
		value = "content/ui/materials/backgrounds/default_square",
		style = {
			color = Color.terminal_corner_hover(255, true),
			size = {
				RARITY_BAR_WIDTH,
				height,
			},
			offset = {
				0,
				0,
				9,
			},
		},
	}

	passes[#passes + 1] = {
		pass_type = "texture",
		style_id = "deleted_icon",
		value = "content/ui/materials/icons/items/equipped_label",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			size = {
				check_size,
				check_size,
			},
			offset = {
				0,
				0,
				16,
			},
		},
		visibility_function = function(content)
			return content.multi_selected or false
		end,
	}

	passes[#passes + 1] = {
		pass_type = "rect",
		style_id = "deleted_icon_background",
		style = {
			color = Color.black(127.5, true),
			offset = {
				0,
				0,
				15,
			},
		},
		visibility_function = function(content)
			return content.multi_selected or false
		end,
	}

	passes[#passes + 1] = {
		pass_type = "texture",
		style_id = "equipped_icon",
		value = "content/ui/materials/icons/items/equipped_label",
		style = {
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = {
				equipped_size,
				equipped_size,
			},
			offset = {
				layout.text_x,
				2,
				16,
			},
		},
		visibility_function = function(content)
			return content.equipped or false
		end,
	}

	passes[#passes + 1] = {
		pass_type = "text",
		style_id = "favorite_icon",
		value = favorite_label(layout),
		style = {
			font_type = UIFontSettings.body_small.font_type,
			font_size = layout.favorite_font,
			horizontal_alignment = "right",
			vertical_alignment = "top",
			text_horizontal_alignment = "right",
			text_vertical_alignment = "top",
			text_color = Color.terminal_text_header(255, true),
			size = {
				layout.favorite_font,
				layout.favorite_font + 8,
			},
			offset = {
				-4,
				4,
				16,
			},
		},
		visibility_function = function(content)
			return content.favorite or false
		end,
		change_function = function(content, style)
			style.size[1] = (content.favorite_width or layout.favorite_font) + 2
		end,
	}

	passes[#passes + 1] = {
		pass_type = "texture",
		style_id = "frame",
		value = "content/ui/materials/frames/frame_tile_2px",
		style = {
			color = Color.terminal_frame(nil, true),
			default_color = Color.terminal_frame(nil, true),
			selected_color = Color.terminal_frame_selected(nil, true),
			hover_color = Color.terminal_frame_hover(nil, true),
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = {
				0,
				0,
				15,
			},
		},
		change_function = item_change_function,
	}

	passes[#passes + 1] = {
		pass_type = "texture",
		style_id = "corner",
		value = "content/ui/materials/frames/frame_corner_2px",
		style = {
			color = Color.terminal_corner(nil, true),
			default_color = Color.terminal_corner(nil, true),
			selected_color = Color.terminal_corner_selected(nil, true),
			hover_color = Color.terminal_corner_hover(nil, true),
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = {
				0,
				0,
				16,
			},
		},
		change_function = item_change_function,
	}

	passes[#passes + 1] = {
		pass_type = "rect",
		style_id = "warning_message_background",
		style = {
			color = {
				150,
				35,
				0,
				0,
			},
			horizontal_alignment = "center",
			vertical_alignment = "top",
			size = {
				nil,
				band_height,
			},
			offset = {
				0,
				math.floor((height - band_height) * 0.5),
				17,
			},
		},
		visibility_function = function(content)
			return content.warning_message and content.warning_message ~= ""
		end,
	}

	passes[#passes + 1] = {
		pass_type = "text",
		style_id = "warning_message",
		value = "",
		value_id = "warning_message",
		style = {
			font_type = UIFontSettings.header_3.font_type,
			font_size = clamp_font_size(math.floor(height * 0.24), 14, 22),
			text_horizontal_alignment = "center",
			text_vertical_alignment = "center",
			horizontal_alignment = "center",
			vertical_alignment = "center",
			text_color = {
				255,
				159,
				67,
				67,
			},
			size = {
				nil,
				band_height,
			},
			offset = {
				0,
				0,
				18,
			},
		},
		visibility_function = function(content)
			return content.warning_message and content.warning_message ~= ""
		end,
	}

	return passes
end

local function set_stats_content(content, item)
	local stats = ItemStats and ItemStats.get_display_stats(item)

	if not stats then
		content.stats_visible = false

		return
	end

	content.stats_visible = true

	local show_names = mod:get("show_stat_abbreviations")

	for i = 1, NUM_STATS do
		local stat = stats[i]

		content["has_stat_" .. i] = stat ~= nil
		content["has_abbr_" .. i] = stat ~= nil and show_names and stat.abbreviation ~= nil or false
		content["stat_abbr_" .. i] = stat and stat.abbreviation or ""
		content["stat_value_" .. i] = stat and (stat.percentage .. "%") or ""
	end
end

local function apply_item_data(parent, widget, element, ui_renderer, layout)
	local content = widget.content
	local style = widget.style
	local item = element and (element.real_item or element.item)

	if not item then
		return
	end

	local view_instance = parent._parent or parent

	if style.item_level then
		local item_level, has_level = Items.expertise_level(item)

		content.item_level = has_level and item_level or ""
	end

	local item_type = item.item_type
	local ITEM_TYPES = UISettings.ITEM_TYPES
	local is_weapon = item_type == ITEM_TYPES.WEAPON_MELEE or item_type == ITEM_TYPES.WEAPON_RANGED
	local required_level = Items.character_level(item)
	local character_level = view_instance and view_instance.character_level and view_instance:character_level()
	local level_requirement_met = not required_level or (character_level and required_level <= character_level) or not character_level

	content.level_requirement_met = level_requirement_met

	if not level_requirement_met then
		content.required_level = Localize("loc_requires_level", true, {
			level = required_level,
		})
	end

	local rarity_color = Items.rarity_color(item)
	local display_name
	local sub_display_name

	if is_weapon then
		display_name = Items.weapon_card_display_name(item)
		sub_display_name = Items.weapon_card_sub_display_name(item)
		content.rarity_name = Items.rarity_display_name(item)

		if style.rarity_name then
			style.rarity_name.text_color = table.clone(rarity_color)
		end
	else
		display_name = Items.display_name(item)
		sub_display_name = Items.sub_display_name(item)
		content.rarity_name = ""

		if style.sub_display_name then
			style.sub_display_name.text_color = table.clone(rarity_color)
		end
	end

	if ui_renderer and ItemText then
		content.display_name =
			ItemText.truncate(ui_renderer, display_name, UIFontSettings.header_3.font_type, layout.name_font, layout.text_width)

		if style.sub_display_name then
			content.sub_display_name = ItemText.truncate(
				ui_renderer,
				sub_display_name,
				UIFontSettings.body_small.font_type,
				layout.sub_font,
				layout.text_width
			)
		end
	else
		content.display_name = display_name

		if style.sub_display_name then
			content.sub_display_name = sub_display_name
		end
	end

	style.background_gradient.color = table.clone(rarity_color)

	if style.rarity_tag then
		style.rarity_tag.color = table.clone(rarity_color)
	end

	if ui_renderer and style.favorite_icon then
		content.favorite_width = math.ceil(UIRenderer.text_size(
			ui_renderer,
			favorite_label(layout),
			style.favorite_icon.font_type,
			style.favorite_icon.font_size
		))
	end

	if layout.stats_row_visible then
		set_stats_content(content, item)
	else
		content.stats_visible = false
	end
end

mod.create_compact_blueprint = function(width, height)
	local layout = compute_layout(width, height, mod:get("show_item_stats") == true)

	return {
		size = {
			width,
			height,
		},
		pass_template = create_pass_template(layout),
		init = function(
			parent,
			widget,
			element,
			callback_name,
			secondary_callback_name,
			ui_renderer,
			double_click_callback
		)
			local content = widget.content
			local hotspot = content.hotspot

			hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element)
			hotspot.right_pressed_callback = secondary_callback_name
				and callback(parent, secondary_callback_name, widget, element)
			hotspot.double_click_callback = double_click_callback
				and callback(parent, double_click_callback, widget, element)

			content.element = element

			apply_item_data(parent, widget, element, ui_renderer, layout)
		end,
		load_icon = function(parent, widget, element, ui_renderer, dummy_profile, prioritize)
			local content = widget.content
			local item = element.item or element.real_item

			if not layout.show_icon or content.icon_load_id or not item then
				return
			end

			local cb = callback(apply_live_item_icon, widget)
			local render_context = {
				alignment_key = element.alignment_key,
				alignment_key_value = element.alignment_key_value,
				size = element.render_size,
			}

			content.icon_load_id = Managers.ui:load_item_icon(item, cb, render_context, dummy_profile, prioritize)
		end,
		unload_icon = function(parent, widget, element, ui_renderer)
			local content = widget.content

			if content.icon_load_id then
				remove_live_item_icon(widget, ui_renderer)
				Managers.ui:unload_item_icon(content.icon_load_id)

				content.icon_load_id = nil
			end
		end,
		destroy = function(parent, widget, element, ui_renderer)
			local content = widget.content

			if content.icon_load_id then
				remove_live_item_icon(widget, ui_renderer)
				Managers.ui:unload_item_icon(content.icon_load_id)

				content.icon_load_id = nil
			end
		end,
		update = function(parent, widget, input_service, dt, t, ui_renderer)
			local content = widget.content
			local element = content.element

			if not element then
				return
			end

			local item = element.real_item or element.item
			local slot = element.slot
			local view_instance = parent._parent or parent

			if item and item.gear_id then
				content.favorite = Items.is_item_id_favorited(item.gear_id) and true or false
			end

			if item and slot then
				local item_type = item.item_type
				local is_equipped

				if item_type == UISettings.ITEM_TYPES.GADGET then
					is_equipped = is_item_equipped_in_any_slot(view_instance, item, item.slots)
				else
					is_equipped = is_item_equipped_in_slot(view_instance, item, slot.name)
				end

				content.equipped = is_equipped
			end
		end,
		update_data = function(parent, widget, element)
			apply_item_data(parent, widget, element, nil, layout)
		end,
		update_item_icon_priority = function(parent, widget, element, ui_renderer, dummy_profile)
			local content = widget.content

			if content.icon_load_id then
				Managers.ui:update_item_icon_priority(content.icon_load_id)
			end
		end,
		style_function = function(parent, config, size)
			return config and config.style_override
		end,
	}
end
