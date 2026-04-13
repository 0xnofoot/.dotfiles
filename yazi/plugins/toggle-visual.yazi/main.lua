--- @sync entry

local M = {}
local in_select = true

function M:entry()
	if not cx.active.mode.is_visual then
		ya.emit("visual_mode", {})
		in_select = true
	elseif in_select then
		ya.emit("escape", {})
		ya.emit("visual_mode", { unset = true })
		in_select = false
	else
		ya.emit("escape", {})
		ya.emit("visual_mode", {})
		in_select = true
	end
end

return M
