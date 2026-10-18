local mod = get_mod("inventory_improved")

local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")

local COMPACT_WIDGET_TYPE = mod.COMPACT_WIDGET_TYPE
local COMPACT_CARD_MIN_WIDTH = 64
local COMPACT_CARD_DEFAULT_HEIGHT = 72

local compact_card_logged = false

local origin_grid_widths = setmetatable({}, {
	__mode = "k",
})

local function apply_grid_width(menu_settings, items_per_row, allow_expand)
	local grid_size = menu_settings.grid_size
	local origin = origin_grid_widths[menu_settings]

	if not origin then
		origin = {
			grid_width = grid_size[1],
			mask_width = menu_settings.mask_size[1],
		}
		origin_grid_widths[menu_settings] = origin
	end

	local target_grid_width = origin.grid_width

	if allow_expand and items_per_row >= 3 then
		local edge_padding = menu_settings.edge_padding or 0

		target_grid_width = math.max(origin.grid_width, origin.mask_width - edge_padding)
	end

	grid_size[1] = target_grid_width

	return target_grid_width
end

local function present_default(
	func,
	self,
	layout,
	content_blueprints,
	left_click_callback,
	right_click_callback,
	display_name,
	optional_grow_direction,
	optional_on_present_callback,
	optional_left_double_click_callback
)
	return func(
		self,
		layout,
		content_blueprints,
		left_click_callback,
		right_click_callback,
		display_name,
		optional_grow_direction,
		optional_on_present_callback,
		optional_left_double_click_callback
	)
end

local function revert_compact_entries(layout)
	if not layout then
		return
	end

	for i = 1, #layout do
		local entry = layout[i]

		if entry.widget_type == COMPACT_WIDGET_TYPE then
			entry.widget_type = "item"
			entry.render_size = nil
			entry.entry_id = nil
		end
	end
end

mod:hook(
	ViewElementGrid,
	"present_grid_layout",
	function(
		func,
		self,
		layout,
		content_blueprints,
		left_click_callback,
		right_click_callback,
		display_name,
		optional_grow_direction,
		optional_on_present_callback,
		optional_left_double_click_callback
	)
		local items_per_row = mod:get("items_per_row") or 1
		local parent = self._parent

		if
			not parent
			or parent.__class_name ~= "InventoryWeaponsView"
			or not content_blueprints
		then
			apply_grid_width(self._menu_settings, items_per_row, false)
			revert_compact_entries(layout)

			return present_default(
				func,
				self,
				layout,
				content_blueprints,
				left_click_callback,
				right_click_callback,
				display_name,
				optional_grow_direction,
				optional_on_present_callback,
				optional_left_double_click_callback
			)
		end

		local menu_settings = self._menu_settings
		local grid_spacing = menu_settings.grid_spacing or {
			10,
			10,
		}
		local target_grid_width = apply_grid_width(menu_settings, items_per_row, true)

		local cell_width = math.max(
			math.floor((target_grid_width - grid_spacing[1] * (items_per_row - 1)) / items_per_row),
			COMPACT_CARD_MIN_WIDTH
		)
		local cell_height = mod:get("compact_card_height") or COMPACT_CARD_DEFAULT_HEIGHT

		content_blueprints[COMPACT_WIDGET_TYPE] = mod.create_compact_blueprint(cell_width, cell_height)

		if not compact_card_logged then
			compact_card_logged = true

			mod:warning(
				"compact grid style active: cell=%sx%s type=%s",
				tostring(cell_width),
				tostring(cell_height),
				tostring(COMPACT_WIDGET_TYPE)
			)
		end

		if layout then
			for i = 1, #layout do
				local entry = layout[i]

				if entry.widget_type == "item" then
					entry.widget_type = COMPACT_WIDGET_TYPE
					entry.render_size = {
						cell_width,
						cell_height,
					}
					entry.entry_id = nil
				end
			end
		end

		local success, err = xpcall(
			func,
			debug.traceback,
			self,
			layout,
			content_blueprints,
			left_click_callback,
			right_click_callback,
			display_name,
			optional_grow_direction,
			optional_on_present_callback,
			optional_left_double_click_callback
		)

		if success then
			return
		end

		mod:error("compact grid style failed, using default item cards:\n%s", tostring(err))

		apply_grid_width(self._menu_settings, items_per_row, false)
		revert_compact_entries(layout)

		return present_default(
			func,
			self,
			layout,
			content_blueprints,
			left_click_callback,
			right_click_callback,
			display_name,
			optional_grow_direction,
			optional_on_present_callback,
			optional_left_double_click_callback
		)
	end
)

mod.grid_style_refresh = function()
	local ui_manager = Managers.ui
	local view = ui_manager and ui_manager:view_instance("inventory_weapons_view")
	local layout = view and view._offer_items_layout

	if not layout then
		return
	end

	for i = 1, #layout do
		layout[i].entry_id = nil
	end

	view:present_grid_layout(layout, callback(view, "_cb_on_present"))
end
