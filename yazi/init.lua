-- Tab bar: 2 rows height for visual gap from file list
function Tabs.height()
	return #cx.tabs > 1 and 2 or 0
end

-- Custom tab rendering: clean style with spacing
function Tabs:redraw()
	if self.height() < 1 then
		return {}
	end

	local lines = {}
	local pos = 0
	local max = math.floor(self:inner_width() / #cx.tabs)
	local sep_style = ui.Style():fg("#665c54")

	for i = 1, #cx.tabs do
		local name = ui.truncate(string.format(" %d %s ", i, cx.tabs[i].name), { max = max })

		if i > 1 then
			lines[#lines + 1] = ui.Line(ui.Span("  "):style(sep_style))
			pos = pos + 2
		end

		if i == cx.tabs.idx then
			lines[#lines + 1] = ui.Line(name):style(th.tabs.active)
		else
			lines[#lines + 1] = ui.Line(name):style(th.tabs.inactive)
		end

		self._offsets[i], pos = pos, pos + lines[#lines]:width()
	end

	return ui.Line(lines):area(self._area)
end
