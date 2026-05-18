--- @since 25.5.31
--- 弹出 yazi 原生 confirm 对话框，确认后调用 trash-put 把文件移入 ~/.local/share/Trash/
--- 配套 restore.yazi，使删除路径与 restore 找回路径在 macOS / Linux 上完全对齐

local M = {}

local PackageName = "Trash"

local get_targets = ya.sync(function()
	local urls = {}
	for _, u in pairs(cx.active.selected) do
		urls[#urls + 1] = tostring(u)
	end
	if #urls == 0 then
		local h = cx.active.current.hovered
		if h then
			urls[#urls + 1] = tostring(h.url)
		end
	end
	return urls
end)

local function basename(p)
	return p:match("([^/]+)/?$") or p
end

function M:entry()
	local urls = get_targets()
	if #urls == 0 then
		return
	end

	local lines = {}
	local max_show = 10
	for i, p in ipairs(urls) do
		if i > max_show then
			lines[#lines + 1] = ui.Line(string.format("… and %d more", #urls - max_show))
			break
		end
		lines[#lines + 1] = ui.Line(basename(p))
	end

	local title = #urls == 1 and "Trash 1 item?" or string.format("Trash %d items?", #urls)
	local ok = ya.confirm({
		pos = { "center", w = 70, h = math.min(#lines + 4, 20) },
		title = ui.Line(title):style(ui.Style():fg("yellow")),
		body = ui.Text(lines),
	})
	if not ok then
		return
	end

	local args = { "--" }
	for _, p in ipairs(urls) do
		args[#args + 1] = p
	end

	local output, err = Command("trash-put"):arg(args):output()
	if not output then
		ya.notify({
			title = PackageName,
			content = "Failed to run trash-put: " .. tostring(err),
			level = "error",
			timeout = 5,
		})
		return
	end
	if not output.status.success then
		ya.notify({
			title = PackageName,
			content = (output.stderr ~= "" and output.stderr) or "trash-put exited with error",
			level = "error",
			timeout = 5,
		})
	end
end

return M
