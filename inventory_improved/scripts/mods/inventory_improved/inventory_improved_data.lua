local mod = get_mod("inventory_improved")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,

	options = {
		widgets = {
			{
				setting_id = "general_settings",
				type = "group",

				sub_widgets = {
					{
						setting_id = "mod_name_pizazz_toggle",
						type = "checkbox",
						default_value = true,
						tooltip = "mod_name_pizazz_tooltip",
					},
				},
			},
			{
				setting_id = "item_grid_settings",
				type = "group",

				sub_widgets = {
					{
						setting_id = "items_per_row",
						type = "numeric",
						default_value = 1,
						tooltip = "items_per_row_tooltip",
						range = { 1, 5 },
						step_size_value = 1,
						decimals_number = 0,
					},
					{
						setting_id = "compact_card_height",
						type = "numeric",
						default_value = 72,
						tooltip = "compact_card_height_tooltip",
						range = { 48, 112 },
						step_size_value = 4,
						decimals_number = 0,
					},
					{
						setting_id = "show_item_stats",
						type = "checkbox",
						default_value = true,
						tooltip = "show_item_stats_tooltip",
					},
					{
						setting_id = "show_stat_abbreviations",
						type = "checkbox",
						default_value = true,
						tooltip = "show_stat_abbreviations_tooltip",
					},
				},
			},
			{
				setting_id = "interface_settings",
				type = "group",

				sub_widgets = {
					{
						setting_id = "show_settings_button",
						type = "checkbox",
						default_value = true,
						tooltip = "show_settings_button_tooltip",
					},
				},
			},
		},
	},
}
