local M = {
    'saghen/blink.cmp',
    version = '1.*',

    dependencies = {
        'rafamadriz/friendly-snippets',
    },

    config = function()
        vim.api.nvim_set_hl(0, 'BlinkCmpDoc', { bg = '#1E2A35' })
        vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { fg = '#555F6F', bg = '#1E2A35' })

        require('blink.cmp').setup({
            keymap = {
                preset = 'none',
                ['<C-j>'] = { 'scroll_documentation_down' },
                ['<C-k>'] = { 'scroll_documentation_up' },
                ['<C-c>'] = { 'cancel', 'fallback' },
                ['<CR>'] = { 'accept', 'fallback' },
                ['<C-a>'] = { 'show', 'hide', 'fallback' },
                ['<Tab>'] = { 'select_next', 'fallback' },
                ['<S-Tab>'] = { 'select_prev', 'fallback' },
            },

            cmdline = {
                enabled = true,
                keymap = {
                    preset = 'cmdline',
                    ['<Tab>'] = { 'select_next', 'fallback' },
                    ['<S-Tab>'] = { 'select_prev', 'fallback' },
                },
                completion = {
                    menu = { auto_show = true },
                    ghost_text = { enabled = false },
                },
            },

            completion = {
                accept = {
                    auto_brackets = { enabled = true },
                },
                documentation = {
                    auto_show = true,
                    window = { border = 'rounded' },
                },
                ghost_text = { enabled = true },
                menu = {
                    min_width = 60,
                    border = 'rounded',
                    -- 调整 cmdline 补全菜单位置，使其与 noice 输入框对齐
                    cmdline_position = function()
                        if vim.g.ui_cmdline_pos ~= nil then
                            local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
                            return { pos[1] - 1 + 1, pos[2] - 1 }
                        end
                        local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
                        return { vim.o.lines - height, 0 }
                    end,
                    draw = {
                        columns = {
                            { 'kind_icon' },
                            { 'label', 'label_description', gap = 1 },
                        },
                    },
                },
                list = {
                    selection = { preselect = true, auto_insert = false },
                },
            },

            signature = { enabled = true },

            appearance = {
                kind_icons = {
                    Text = '󰉿',
                    Method = '󰆧',
                    Function = '󰡱',
                    Constructor = '',
                    Field = '󰜢',
                    Variable = '󰀫',
                    Class = '󰠱',
                    Interface = '',
                    Module = '',
                    Property = '󰜢',
                    Unit = '󰑭',
                    Value = '󰎠',
                    Enum = '',
                    Keyword = '󰌋',
                    Snippet = '',
                    Color = '󰏘',
                    File = '󰈙',
                    Reference = '󰈇',
                    Folder = '󰉋',
                    EnumMember = '',
                    Constant = '󰏿',
                    Struct = '󰙅',
                    Event = '',
                    Operator = '󰆕',
                    TypeParameter = '',
                },
            },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
        })
    end,
}

return M
