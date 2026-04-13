local function getCurrentTabWinCount()
    local current_tab_win_count = 0
    local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
    for _, win in ipairs(wins) do
        local winType = vim.fn.win_gettype(win)

        if winType ~= "popup" and winType ~= "preview" then
            current_tab_win_count = current_tab_win_count + 1
        end
    end

    return current_tab_win_count
end
vim.g.getCurrentTabWinCount = getCurrentTabWinCount

local function quitNvim()
    local isModified = vim.bo[vim.api.nvim_get_current_buf()].modified

    if isModified then
        vim.api.nvim_echo({ { "No write since last change!!!", "ErrorMsg" } }, false, {})
        return
    end

    vim.api.nvim_command("OutlineClose")

    local current_buf_of_win_count = #vim.fn.getbufinfo(vim.fn.bufnr("%"))[1].windows
    local buf_count = vim.fn.len(vim.fn.getbufinfo({ buflisted = 1 }))

    if buf_count == 1 and current_buf_of_win_count == 1 then
        vim.api.nvim_command("quit")
        return
    end

    if current_buf_of_win_count == 1 then
        -- depend on the nvim tree open state
        if vim.g[vim.g.getNvimTreeOpenStateIndex()] and getCurrentTabWinCount() == 2 then
            local current_buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_command("bprevious")
            vim.api.nvim_buf_delete(current_buf, { force = true })
        else
            vim.api.nvim_command("bdelete")
        end
    else
        vim.api.nvim_command("close")
    end
end
vim.g.quitNvim = quitNvim

local function showDeepTable(table, indent)
    indent = indent or 0
    for key, value in pairs(table) do
        if type(value) == "table" then
            print(string.rep("  ", indent) .. key .. ":")
            showDeepTable(value, indent + 1)
        else
            print(string.rep("  ", indent) .. key .. ": " .. tostring(value))
        end
    end
end
vim.g.showDeepTable = showDeepTable
