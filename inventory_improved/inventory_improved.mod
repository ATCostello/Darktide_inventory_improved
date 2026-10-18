return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`inventory_improved` encountered an error loading the Darktide Mod Framework.")

		new_mod("inventory_improved", {
			mod_script       = "inventory_improved/scripts/mods/inventory_improved/inventory_improved",
			mod_data         = "inventory_improved/scripts/mods/inventory_improved/inventory_improved_data",
			mod_localization = "inventory_improved/scripts/mods/inventory_improved/inventory_improved_localization",
		})
	end,
	packages = {},
}
