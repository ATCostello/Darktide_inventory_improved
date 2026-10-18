local mod = get_mod("inventory_improved")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local CustomSettingsView = require("scripts/ui/views/custom_settings_view/custom_settings_view")
local InventoryView = require("scripts/ui/views/inventory_view/inventory_view")
local InventoryWeaponsView = require("scripts/ui/views/inventory_weapons_view/inventory_weapons_view")
local UIWidget = require("scripts/managers/ui/ui_widget")

local SETTINGS_ROW_WIDTH = 860
local SETTINGS_ROW_HEIGHT = 64
local SETTINGS_VALUE_WIDTH = 340

local SETTINGS_BUTTON_NAME = "inventory_improved_settings_button"
local SETTINGS_BUTTON_SIZE = { 140, 40 }
local SETTINGS_BUTTON_OFFSETS = {
	inventory_view = { 1690, 90, 10 },
	inventory_weapons_view = { 1600, 40, 10 },
}

local LIVE_REFRESH_SETTINGS = {
	items_per_row = true,
	compact_card_height = true,
	show_item_stats = true,
	show_stat_abbreviations = true,
}

local SETTINGS_PANEL_NAME = "inventory_improved_settings_panel"
local SETTINGS_PANEL_WIDTH = 960
local SETTINGS_PANEL_HEIGHT = 1080
local SETTINGS_PANEL_OFFSET_X = 960
local SETTINGS_CONTENT_SHIFT_X = 480
local SETTINGS_CONTENT_BLUR_EDGE = 8
local SETTINGS_SLIDE_OFFSET = 960
local SETTINGS_SLIDE_DURATION = 0.35

-- section: settings overlay adapter

local function convert_widget_to_entries(dmf_widget, entries)
	local widget_type = dmf_widget.type
	local setting_id = dmf_widget.setting_id

	if widget_type == "group" then
		entries[#entries + 1] = {
			widget_type = "description",
			display_name = setting_id,
			shrink_to_fit = true,
		}

		for _, sub_widget in ipairs(dmf_widget.sub_widgets or {}) do
			convert_widget_to_entries(sub_widget, entries)
		end

		entries[#entries + 1] = {
			widget_type = "large_spacing",
		}

		return
	end

	if widget_type == "checkbox" then
		entries[#entries + 1] = {
			widget_type = "checkbox",
			display_name = setting_id,
			tooltip_text = dmf_widget.tooltip,
			size = { SETTINGS_ROW_WIDTH, SETTINGS_ROW_HEIGHT },
			value_width = SETTINGS_VALUE_WIDTH,
			get_function = function()
				return mod:get(setting_id)
			end,
			on_activated = function(value)
				mod:set(setting_id, value)

				if setting_id == "show_settings_button" then
					mod.settings_button_set_visible(value)
				end

				if LIVE_REFRESH_SETTINGS[setting_id] and mod.grid_style_refresh then
					mod.grid_style_refresh()
				end
			end,
		}
	elseif widget_type == "numeric" then
		local range = dmf_widget.range
		local step_size = dmf_widget.step_size_value or 1
		local decimals = dmf_widget.decimals_number or 0
		local number_format = string.format("%%.%df", decimals)

		entries[#entries + 1] = {
			widget_type = "value_slider",
			display_name = setting_id,
			tooltip_text = dmf_widget.tooltip,
			min_value = range[1],
			max_value = range[2],
			num_decimals = decimals,
			step_size_value = step_size,
			focusable = true,
			size = { SETTINGS_ROW_WIDTH, SETTINGS_ROW_HEIGHT },
			value_width = SETTINGS_VALUE_WIDTH,
			get_function = function()
				return mod:get(setting_id)
			end,
			explode_function = function(normalized_value, template)
				local value_range = template.max_value - template.min_value
				local exploded_value = template.min_value + normalized_value * value_range

				return math.round(exploded_value / step_size) * step_size
			end,
			format_value_function = function(value)
				return string.format(number_format, value)
			end,
			on_activated = function(value)
				mod:set(setting_id, value)

				if LIVE_REFRESH_SETTINGS[setting_id] and mod.grid_style_refresh then
					mod.grid_style_refresh()
				end
			end,
		}
	elseif widget_type == "dropdown" then
		local options = {}

		for _, option in ipairs(dmf_widget.options or {}) do
			options[#options + 1] = {
				id = option.value,
				display_name = option.text,
				ignore_localization = true,
			}
		end

		entries[#entries + 1] = {
			widget_type = "dropdown",
			display_name = setting_id,
			tooltip_text = dmf_widget.tooltip,
			options = options,
			size = { SETTINGS_ROW_WIDTH, SETTINGS_ROW_HEIGHT },
			value_width = SETTINGS_VALUE_WIDTH,
			get_function = function()
				return mod:get(setting_id)
			end,
			on_activated = function(value)
				mod:set(setting_id, value)
			end,
		}
	end
end

local function build_pages()
	local data = mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/inventory_improved_data")
	local entries = {}

	for _, dmf_widget in ipairs(data.options.widgets) do
		convert_widget_to_entries(dmf_widget, entries)
	end

	return {
		{
			title = mod:localize("settings_overlay_title"),
			widgets = entries,
		},
	}
end

mod.open_settings_overlay = function()
	local pages = build_pages()

	Managers.ui:open_view("custom_settings_view", nil, nil, nil, nil, {
		pages = pages,
		can_exit = true,
		inventory_improved_settings_panel = true,
	})
end

-- section: inventory screen settings button

local function create_settings_button(view, view_name)
	if view._widgets_by_name[SETTINGS_BUTTON_NAME] then
		return
	end

	local offset = SETTINGS_BUTTON_OFFSETS[view_name]
	local widget_definition =
		UIWidget.create_definition(ButtonPassTemplates.default_button, "canvas", nil, SETTINGS_BUTTON_SIZE)
	local widget = view:_create_widget(SETTINGS_BUTTON_NAME, widget_definition)

	widget.offset[1] = offset[1]
	widget.offset[2] = offset[2]
	widget.offset[3] = offset[3]
	widget.content.original_text = mod:localize("settings_button_text")
	widget.content.hotspot.pressed_callback = function()
		mod.open_settings_overlay()
	end

	table.insert(view._widgets, widget)
end

local function remove_settings_button(view)
	local widget = view._widgets_by_name[SETTINGS_BUTTON_NAME]

	if not widget then
		return
	end

	view:_unregister_widget_name(SETTINGS_BUTTON_NAME)

	for i = #view._widgets, 1, -1 do
		if view._widgets[i] == widget then
			table.remove(view._widgets, i)

			break
		end
	end
end

mod.settings_button_set_visible = function(visible)
	local ui_manager = Managers.ui

	if not ui_manager then
		return
	end

	local view_names = {
		"inventory_view",
		"inventory_weapons_view",
	}

	for i = 1, #view_names do
		local view_name = view_names[i]
		local view = ui_manager:view_instance(view_name)

		if view then
			if visible then
				create_settings_button(view, view_name)
			else
				remove_settings_button(view)
			end
		end
	end
end

mod:hook(InventoryView, "on_enter", function(func, self)
	func(self)

	if mod:get("show_settings_button") then
		create_settings_button(self, "inventory_view")
	end
end)

mod:hook(InventoryWeaponsView, "on_enter", function(func, self)
	func(self)

	if mod:get("show_settings_button") then
		create_settings_button(self, "inventory_weapons_view")
	end
end)

-- section: half-screen settings panel

local settings_panel_passes = {
	{
		pass_type = "rect",
		style = {
			color = Color.black(255, true),
			offset = { 0, 0, 0 },
		},
	},
	{
		pass_type = "rect",
		style = {
			color = Color.black(127.5, true),
			offset = { 0, 0, 3 },
		},
	},
	{
		pass_type = "slug_icon",
		value = "content/ui/vector_textures/symbols/cog_skull_01",
		style = {
			color = { 40, 0, 0, 0 },
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = { 0, 0, 2 },
			size = { 800, 800 },
		},
	},
	{
		pass_type = "texture",
		value = "content/ui/materials/backgrounds/terminal_basic",
		style = {
			color = Color.terminal_grid_background_gradient(255, true),
			horizontal_alignment = "center",
			vertical_alignment = "center",
			scale_to_material = true,
			size_addition = { 40, 40 },
			offset = { -20, -20, 1 },
		},
	},
}

local function create_settings_panel(view)
	local widgets_by_name = view._widgets_by_name

	if widgets_by_name[SETTINGS_PANEL_NAME] then
		return
	end

	local definition = UIWidget.create_definition(
		settings_panel_passes,
		"canvas",
		nil,
		{ SETTINGS_PANEL_WIDTH, SETTINGS_PANEL_HEIGHT }
	)
	local widget = view:_create_widget(SETTINGS_PANEL_NAME, definition)

	widget.offset[1] = SETTINGS_PANEL_OFFSET_X
	widget.offset[2] = 0
	widget.offset[3] = 0

	table.insert(view._widgets, 1, widget)
end

mod:hook(CustomSettingsView, "init", function(func, self, settings, context)
	func(self, settings, context)

	self._inventory_improved_settings_panel = context and context.inventory_improved_settings_panel or false
end)

mod:hook(CustomSettingsView, "on_enter", function(func, self)
	func(self)

	if not self._pages or not self._inventory_improved_settings_panel then
		return
	end

	create_settings_panel(self)

	local background_widget = self._widgets_by_name.background

	if background_widget then
		background_widget.content.visible = false
	end

	local scenegraph = self._ui_scenegraph

	scenegraph.area.position[1] = SETTINGS_CONTENT_SHIFT_X

	local content_height = scenegraph.grid_start.size[2]

	self:_set_scenegraph_size("grid_start", SETTINGS_ROW_WIDTH, content_height)
	self:_set_scenegraph_size("grid_content_pivot", SETTINGS_ROW_WIDTH, content_height)
	self:_set_scenegraph_size(
		"grid_content_mask",
		SETTINGS_ROW_WIDTH + SETTINGS_CONTENT_BLUR_EDGE * 2,
		content_height + SETTINGS_CONTENT_BLUR_EDGE * 2
	)
	self:_set_scenegraph_size("grid_content_interaction", SETTINGS_ROW_WIDTH + 20, content_height)

	if self._grid then
		self._grid:force_update_list_size()
	end

	scenegraph.canvas.position[1] = SETTINGS_SLIDE_OFFSET
	self._inventory_improved_slide_time = 0
	self._update_scenegraph = true
end)

mod:hook(CustomSettingsView, "update", function(func, self, dt, t, input_service, layer)
	func(self, dt, t, input_service, layer)

	local slide_time = self._inventory_improved_slide_time

	if not slide_time then
		return
	end

	slide_time = slide_time + (dt or 0)

	local progress = math.min(slide_time / SETTINGS_SLIDE_DURATION, 1)
	local eased = 1 - (1 - progress) ^ 3

	self._ui_scenegraph.canvas.position[1] = SETTINGS_SLIDE_OFFSET * (1 - eased)
	self._update_scenegraph = true

	if progress >= 1 then
		self._inventory_improved_slide_time = nil
	else
		self._inventory_improved_slide_time = slide_time
	end
end)

mod:hook(CustomSettingsView, "_enable_settings_overlay", function(func, self, enable)
	if not self._inventory_improved_settings_panel then
		return func(self, enable)
	end

	local widgets_by_name = self._widgets_by_name
	local settings_overlay_widget = widgets_by_name.settings_overlay

	if settings_overlay_widget then
		settings_overlay_widget.content.visible = false
	end

	local grid_mask_widget = widgets_by_name.grid_content_mask

	if grid_mask_widget then
		grid_mask_widget.offset[3] = enable and 90 or 0
	end
end)
