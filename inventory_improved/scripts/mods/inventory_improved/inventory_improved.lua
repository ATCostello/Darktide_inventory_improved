local mod = get_mod("inventory_improved")

mod.item_text = mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/utils/item_text")
mod.item_stats = mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/utils/item_stats")

mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/modules/compact_card")
mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/modules/grid_style")
mod:io_dofile("inventory_improved/scripts/mods/inventory_improved/modules/settings_overlay")
