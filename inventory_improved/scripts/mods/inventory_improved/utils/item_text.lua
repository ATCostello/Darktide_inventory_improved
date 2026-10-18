local mod = get_mod("inventory_improved")

local UIRenderer = require("scripts/managers/ui/ui_renderer")

local text_size = UIRenderer.text_size
local ELLIPSIS = "…"

local ItemText = {}

ItemText.truncate = function(ui_renderer, text, font_type, font_size, max_width)
	if not text or text == "" or not ui_renderer or not max_width or max_width <= 0 then
		return text or ""
	end

	local width = text_size(ui_renderer, text, font_type, font_size)

	if width <= max_width then
		return text
	end

	local ellipsis_width = text_size(ui_renderer, ELLIPSIS, font_type, font_size)
	local target_width = max_width - ellipsis_width

	if target_width <= 0 then
		return ELLIPSIS
	end

	local length = Utf8.string_length(text)
	local low = 1
	local high = length
	local best = ""

	while low <= high do
		local mid = math.floor((low + high) * 0.5)
		local candidate = Utf8.sub_string(text, 1, mid)
		local candidate_width = text_size(ui_renderer, candidate, font_type, font_size)

		if candidate_width <= target_width then
			best = candidate
			low = mid + 1
		else
			high = mid - 1
		end
	end

	if best == "" then
		return ELLIPSIS
	end

	return best .. ELLIPSIS
end

return ItemText
