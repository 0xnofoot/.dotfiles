M = {
    {
        -- 基本主题设置
        "theniceboy/nvim-deus",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme deus]])
        end,
    },

    {
        -- 上方代码块面包屑导航
        "Bekaboo/dropbar.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
    },

    {
        -- 上方选项卡
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            options = {
                mode = "buffers",
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level, _, _)
                    local icon = level:match("error") and " " or " "
                    return " " .. icon .. count
                end,
                indicator = {
                    icon = "▎", -- this should be omitted if indicator style is not "icon"
                    -- style = "icon" | "underline" | "none",
                    style = "icon",
                },
                show_buffer_close_icons = false,
                show_close_icon = false,
                enforce_regular_tabs = true,
                show_duplicate_prefix = false,
                tab_size = 16,
                padding = 0,
                separator_style = "thick",
            }
        },
    },

    {
        -- 下方状态栏
        'nvim-lualine/lualine.nvim',
        event = 'VeryLazy',
        config = function()
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = 'auto',
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                    disabled_filetypes = {
                        statusline = {},
                        winbar = {},
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    globalstatus = true,
                    refresh = {
                        statusline = 1000,
                        tabline = 1000,
                        winbar = 1000,
                    }
                },
                sections = {
                    lualine_a = { 'filename' },
                    lualine_b = { 'branch', 'diff', 'diagnostics' },
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = { 'filesize', 'encoding', 'filetype' },
                    lualine_z = { 'location' }
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { 'filename' },
                    lualine_x = { 'location' },
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                extensions = {}
            }
        end
    },

    {
        -- git 符号设置
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup {
                signs                        = {
                    add          = { text = '▎' },
                    change       = { text = '░' },
                    delete       = { text = '_' },
                    topdelete    = { text = '▔' },
                    changedelete = { text = '▒' },
                    untracked    = { text = '┆' },
                },
                signs_staged                 = {
                    add          = { text = '▎' },
                    change       = { text = '░' },
                    delete       = { text = '_' },
                    topdelete    = { text = '▔' },
                    changedelete = { text = '▒' },
                    untracked    = { text = '┆' },
                },
                signs_staged_enable          = true,
                signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
                numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
                linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
                word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
                watch_gitdir                 = {
                    follow_files = true
                },
                auto_attach                  = true,
                attach_to_untracked          = false,
                current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                current_line_blame_opts      = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
                current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
                sign_priority                = 6,
                update_debounce              = 100,
                status_formatter             = nil,   -- Use default
                max_file_length              = 40000, -- Disable if file is longer than this (in lines)
                preview_config               = {
                    -- Options passed to nvim_open_win
                    border = 'single',
                    style = 'minimal',
                    relative = 'cursor',
                    row = 0,
                    col = 1
                },
            }
        end
    },

    {
        -- 右侧滑动条
        'lewis6991/satellite.nvim',
        event = 'VeryLazy',
        opts = {
            current_only = false,
            winblend = 50,
            zindex = 40,
            handlers = {
                cursor = { enable = false },
                search = { enable = false },
                diagnostic = { enable = true },
                gitsigns = { enable = true },
                marks = { enable = false },
            },
        },
    },

    {
        -- 缩进块和代码块线条
        'shellRaining/hlchunk.nvim',
        init = function()
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { pattern = '*', command = 'EnableHL', })
            require('hlchunk').setup({
                chunk = {
                    enable = true,
                    use_treesitter = true,
                    style = {
                        { fg = '#806d9c' },
                    },
                },
                indent = {
                    chars = { '│', '¦', '┆', '┊', },
                    use_treesitter = false,
                },
                blank = {
                    enable = false,
                },
                line_num = {
                    use_treesitter = true,
                },
            })
        end,
    },

    {
        -- 窗口分割美化
        'nvim-zh/colorful-winsep.nvim',
        config = true,
        event = { 'WinNew' },
    },

    {
        -- 彩虹分隔符
        'hiphish/rainbow-delimiters.nvim',
        config = function()
            local rainbow_delimiters = require 'rainbow-delimiters'

            vim.g.rainbow_delimiters = {
                strategy = {
                    [''] = rainbow_delimiters.strategy['global'],
                    vim = rainbow_delimiters.strategy['local'],
                },
                query = {
                    [''] = 'rainbow-delimiters',
                    lua = 'rainbow-blocks',
                },
                priority = {
                    [''] = 110,
                    lua = 210,
                },
                highlight = {
                    'RainbowDelimiterRed',
                    'RainbowDelimiterYellow',
                    'RainbowDelimiterBlue',
                    'RainbowDelimiterOrange',
                    'RainbowDelimiterGreen',
                    'RainbowDelimiterViolet',
                    'RainbowDelimiterCyan',
                },
            }
        end
    },

    {
        -- 命令行浮动窗口 + 消息美化
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        config = function()
            -- 命令行图标 + 边框颜色：: 绿色(默认) / 橙黄 ? 浅蓝
            vim.api.nvim_set_hl(0, 'NoiceCmdlineIconSearch', { fg = '#F5A623' })
            vim.api.nvim_set_hl(0, 'NoiceCmdlinePopupBorderSearch', { fg = '#F5A623' })
            vim.api.nvim_set_hl(0, 'NoiceCmdlineIconSearchUp', { fg = '#7EC8E3' })
            vim.api.nvim_set_hl(0, 'NoiceCmdlinePopupBorderSearch_up', { fg = '#7EC8E3' })

            vim.api.nvim_set_hl(0, 'NoiceFileWrite', { fg = '#D4A959' })

            require('noice').setup({
                cmdline = {
                    view = 'cmdline_popup',
                    format = {
                        cmdline = { icon = ' : ' },
                        search_down = { icon = ' / ', icon_hl_group = 'NoiceCmdlineIconSearch' },
                        search_up = { kind = 'search_up', icon = ' ? ', icon_hl_group = 'NoiceCmdlineIconSearchUp' },
                        filter = { icon = '  ' },
                        lua = { icon = '  ' },
                        help = { icon = '  ' },
                    },
                },
                popupmenu = {
                    enabled = false,
                },
                messages = {
                    view_search = false,
                },
                routes = {
                    {
                        filter = {
                            event = 'msg_show',
                            find = '%[New%]',
                        },
                        opts = { title = 'File', hl_group = 'NoiceFileWrite' },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            find = 'written$',
                        },
                        opts = { title = 'File', hl_group = 'NoiceFileWrite' },
                    },
                },
                lsp = {
                    override = {
                        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                        ['vim.lsp.util.stylize_markdown'] = true,
                    },
                },
                views = {
                    cmdline_popup = {
                        position = {
                            row = 13,
                            col = '50%',
                        },
                    },
                },
                presets = {
                    bottom_search = false,
                    command_palette = true,
                    long_message_to_split = true,
                    lsp_doc_border = true,
                },
            })
        end,
    },
}

return M
