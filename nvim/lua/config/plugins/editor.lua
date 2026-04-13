M = {
    {
        -- 相同词汇高亮
        "RRethy/vim-illuminate",
        config = function()
            require("illuminate").configure({
                providers = {
                    -- "lsp",
                    -- "treesitter",
                    "regex",
                },
            })
            vim.cmd("hi IlluminatedWordText guibg=#494F4D gui=none")
        end
    },

    {
        -- 自动补全列表符号
        "dkarter/bullets.vim",
        event = "VeryLazy",
        ft = { "markdown", "txt" },
    },

    {
        -- 补全括号
        "windwp/nvim-autopairs",
        event = "BufRead",
        config = function()
            require("nvim-autopairs").setup({})
        end
    },

    {
        -- 复制粘贴增强
        "gbprod/yanky.nvim",
        event = "VeryLazy",
        dependencies = {
            "kkharji/sqlite.lua",
        },
        config = function()
            -- 使用系统剪切板
            vim.cmd("set clipboard=unnamedplus")

            vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleForward)")
            vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleBackward)")
            vim.keymap.set({ "n", "v", "x" }, "p", "<Plug>(YankyPutAfter)")
            vim.keymap.set({ "n", "v", "x" }, "P", "<Plug>(YankyPutBefore)")

            require("yanky").setup({
                ring = {
                    history_length = 2000,
                    storage = "sqlite",
                    sync_with_numbered_registers = true,
                    cancel_event = "update",
                },
                picker = {
                    select = {
                        action = nil, -- nil to use default put action
                    },
                },
                system_clipboard = {
                    sync_with_ring = true,
                },
                highlight = {
                    on_put = true,
                    on_yank = true,
                    timer = 300,
                },
                preserve_cursor_position = {
                    enabled = true,
                },
            })
        end
    },

    {
        -- 当前页面快速搜索跳转
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            labels = "arstneiowfuydh",
            jump = {
                jumplist = true,
                pos = "start",
                history = false,
                register = false,
                nohlsearch = false,
                autojump = false,
                inclusive = nil,
            },
            label = {
                uppercase = false,
                exclude = "",
                current = false,
                after = true,
                before = false,
                style = "inline",
                reuse = "all",
                distance = true,
                min_pattern_length = 0,
                rainbow = {
                    enabled = true,
                    shade = 8,
                },
            },
            modes = {
                search = {
                    enabled = false,
                },
                char = {
                    enabled = false,
                },
                treesitter = {
                    labels = "arstneiowfuydh",
                    jump = { pos = "range" },
                    search = { incremental = false },
                    label = { before = true, after = true, style = "inline" },
                    highlight = {
                        backdrop = false,
                        matches = false,
                    },
                },
                treesitter_search = {
                    jump = { pos = "range" },
                    search = { multi_window = true, wrap = true, incremental = false },
                    remote_op = { restore = true },
                    label = { before = true, after = true, style = "inline" },
                },
                -- options used for remote flash
                remote = {
                    remote_op = { restore = true, motion = true },
                },
            },
            prompt = {
                enabled = true,
                prefix = { { "⚡", "FlashPromptIcon" } },
                win_config = {
                    relative = "editor",
                    width = 1, -- when <=1 it"s a percentage of the editor width
                    height = 1,
                    row = -1,  -- when negative it"s an offset from the bottom
                    col = 0,   -- when negative it"s an offset from the right
                    zindex = 1000,
                },
            },
        },
        keys = {
            {
                "<leader><leader>",
                mode = { "n" },
                function()
                    require("flash").jump({
                        remote_op = {
                            restore = true,
                            motion = true,
                        },
                    })
                end,
                desc = "Flash",
            },
            {
                "<leader><esc>f",
                mode = { "n", "o", "v", "x" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash Treesitter",
            },
        },
    },


    {
        -- 侧边文件浏览器
        "nvim-tree/nvim-tree.lua",
        version = "*",
        event = "VeryLazy",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            local tree_api = require("nvim-tree.api")

            local function getTreeOpenStateIndex()
                local current_tabnr = vim.api.nvim_get_current_tabpage()
                local current_tab_tree_open_state_index = "current_tab_nvim_tree_opened_state_" .. current_tabnr

                return current_tab_tree_open_state_index
            end

            local function toggleNvimTree()
                local tree_open_state_index = getTreeOpenStateIndex()
                local is_tree_buf = require("nvim-tree.utils").is_nvim_tree_buf()

                if not is_tree_buf then
                    if not vim.g[tree_open_state_index] then
                        tree_api.tree.find_file({ open = true, focus = true, })
                        vim.g[tree_open_state_index] = true
                    else
                        tree_api.tree.focus()
                    end
                else
                    tree_api.tree.close()
                    vim.g[tree_open_state_index] = nil
                end
            end

            vim.keymap.set("n", "<leader>w", toggleNvimTree, { silent = true })

            -- Win Close
            vim.api.nvim_create_autocmd({ "WinEnter" }, {
                callback = function()
                    if not vim.g[getTreeOpenStateIndex()] then
                        return
                    end

                    if #vim.api.nvim_list_tabpages() > 1 and vim.g.getCurrentTabWinCount() == 1 then
                        tree_api.tree.close()
                    end
                end,

                nested = false
            })

            -- Buf Delete (Leave it to keymaps.lua for quit rule function management: quitNvim() )
            vim.g.getNvimTreeOpenStateIndex = getTreeOpenStateIndex

            -- Quit
            vim.api.nvim_create_autocmd({ "QuitPre" }, {
                callback = function()
                    if not vim.g[getTreeOpenStateIndex()] then
                        return
                    end
                    tree_api.tree.close()
                end,

                nested = true
            })

            local function on_attach_func(bufnr)
                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                local function closeNvimtree()
                    vim.api.nvim_command("quit")
                    vim.g[getTreeOpenStateIndex()] = nil
                end

                local function escapeNvimTree()
                    vim.api.nvim_command("wincmd p")
                end

                local function openNewTab()
                    escapeNvimTree()
                    tree_api.node.open.tab()
                end

                local function reMapBufMove(direction)
                    escapeNvimTree()
                    if direction == "next" then
                        vim.api.nvim_command("bnext")
                    elseif direction == "previous" then
                        vim.api.nvim_command("bprevious")
                    end
                end

                vim.keymap.set("n", "?", tree_api.tree.toggle_help, opts("Help"))
                vim.keymap.set("n", "Q", closeNvimtree, opts("Quit"))
                vim.keymap.set("n", "<ESC>", escapeNvimTree, opts("Esc"))
                vim.keymap.set("n", "<c-h>", function() reMapBufMove("previous") end, opts("Previous Buf"))
                vim.keymap.set("n", "<c-l>", function() reMapBufMove("next") end, opts("Next Buf"))

                vim.keymap.set("n", "R", tree_api.tree.reload, opts("Reload"))

                vim.keymap.set("n", ".", tree_api.tree.change_root_to_node, opts("Change Root"))
                -- vim.keymap.set("n", "zz", tree_api.tree.expand_all, opts("Toggle Node"))
                vim.keymap.set("n", "zc", tree_api.node.navigate.parent_close, opts("Close Node"))
                vim.keymap.set("n", "zC", tree_api.tree.collapse_all, opts("Close All Node"))
                vim.keymap.set("n", "zx", tree_api.tree.expand_all, opts("Expand All Node"))

                vim.keymap.set("n", "zh", tree_api.tree.toggle_hidden_filter, opts("Toggle Hidden File"))
                vim.keymap.set("n", "zg", tree_api.tree.toggle_gitignore_filter, opts("Toggle Git Ignore File"))

                vim.keymap.set("n", "h", tree_api.node.navigate.parent, opts("Parent Directory"))

                vim.keymap.set("n", "l", tree_api.node.open.edit, opts("Open Edit"))
                vim.keymap.set("n", "<CR>", tree_api.node.open.no_window_picker, opts("Open Edit No Window Picker"))
                vim.keymap.set("n", "<c-t>", openNewTab, opts("Open New Tab"))
                vim.keymap.set("n", "zl", tree_api.node.open.vertical, opts("Open Vertical"))
                vim.keymap.set("n", "zj", tree_api.node.open.horizontal, opts("Open Horizontal"))

                -- vim.keymap.set("n", "<Tab>", tree_api.node.open.preview, opts("Open Preview"))

                vim.keymap.set("n", "i", tree_api.node.show_info_popup, opts("Show Info"))

                -- if don't you have trash
                -- vim.keymap.set("n", "dD", tree_api.fs.remove, opts("Remove"))
                -- if you have trash
                vim.keymap.set("n", "dD", tree_api.fs.trash, opts("Trash File"))
                vim.keymap.set("n", "dd", tree_api.fs.cut, opts("Cut File"))
                vim.keymap.set("n", "T", tree_api.fs.create, opts("Create File"))

                vim.keymap.set("n", "yy", tree_api.fs.copy.node, opts("Copy File"))
                vim.keymap.set("n", "yn", tree_api.fs.copy.filename, opts("Copy File Name"))
                vim.keymap.set("n", "yp", tree_api.fs.copy.absolute_path, opts("Copy Absolute File Path"))
                vim.keymap.set("n", "yN", tree_api.fs.copy.relative_path, opts("Copy Relative File Path"))
                vim.keymap.set("n", "pp", tree_api.fs.paste, opts("Paste File"))

                -- Rename（对齐 yazi 快捷键）
                local function tree_rename(mode)
                    local node = tree_api.tree.get_node_under_cursor()
                    if not node or node.name == '..' then return end
                    local dir = vim.fn.fnamemodify(node.absolute_path, ':h')
                    local name = node.name
                    local stem = vim.fn.fnamemodify(name, ':r')
                    local ext = vim.fn.fnamemodify(name, ':e')
                    local has_ext = ext ~= ''

                    local default, move_home
                    if mode == 'empty_stem' then
                        default = has_ext and ('.' .. ext) or ''
                        move_home = true
                    elseif mode == 'empty_all' then
                        default = ''
                    elseif mode == 'empty_ext' then
                        default = has_ext and (stem .. '.') or stem
                    elseif mode == 'cursor_start' then
                        default = name
                        move_home = true
                    elseif mode == 'cursor_end' then
                        default = name
                    end

                    if move_home then
                        vim.defer_fn(function()
                            local keys = vim.api.nvim_replace_termcodes('<Home>', true, false, true)
                            vim.api.nvim_feedkeys(keys, 'n', false)
                        end, 50)
                    end

                    vim.ui.input({ prompt = 'Rename: ', default = default }, function(new_name)
                        if not new_name or new_name == '' or new_name == name then return end
                        vim.fn.rename(node.absolute_path, dir .. '/' .. new_name)
                        tree_api.tree.reload()
                    end)
                end

                vim.keymap.set("n", "cn", function() tree_rename('empty_stem') end, opts("Rename (clear name, keep ext)"))
                vim.keymap.set("n", "cw", function() tree_rename('empty_all') end, opts("Rename (clear all)"))
                vim.keymap.set("n", "cI", function() tree_rename('cursor_start') end, opts("Rename (cursor at start)"))
                vim.keymap.set("n", "cA", function() tree_rename('cursor_end') end, opts("Rename (cursor at end)"))
                vim.keymap.set("n", "cs", function() tree_rename('empty_ext') end, opts("Rename (clear ext, keep name)"))


                vim.keymap.set("n", "mm", tree_api.marks.toggle, opts("Toggle Bookmark"))
                vim.keymap.set("n", "mj", tree_api.marks.navigate.next, opts("Next Bookmark"))
                vim.keymap.set("n", "mk", tree_api.marks.navigate.prev, opts("Previous Bookmark"))
                vim.keymap.set("n", "ms", tree_api.marks.navigate.select, opts("Open Bookmark File"))
                vim.keymap.set("n", "mx", tree_api.marks.clear, opts("Clear All  Bookmark"))
                vim.keymap.set("n", "dmd", tree_api.marks.bulk.move, opts("Move Bookmarked"))
                -- if don"t you have trash
                -- vim.keymap.set("n", "dmD", tree_api.marks.bulk.delete, opts("Delete Bookmarked"))
                -- if you have trash
                vim.keymap.set("n", "dmD", tree_api.marks.bulk.trash, opts("Trash Bookmarked"))

                vim.keymap.set("n", "/", tree_api.tree.search_node, opts("Search"))
            end

            vim.opt.termguicolors = true
            require("nvim-tree").setup({
                on_attach = on_attach_func,

                sort = {
                    sorter = "name",
                    folders_first = true,
                    files_first = false,
                },
                view = {
                    width = 60,
                },
                renderer = {
                    group_empty = true,
                    special_files = { "Makefile", "README.md", "readme.md", "README", ".gitignore" },
                    symlink_destination = true,
                    highlight_git = false,
                    highlight_diagnostics = false,
                    highlight_opened_files = "name",
                    highlight_modified = "name",
                    highlight_bookmarks = "name",
                    highlight_clipboard = "name",
                    indent_markers = {
                        enable = true,
                        inline_arrows = true,
                        icons = {
                            corner = "└",
                            edge = "¦",
                            item = "¦",
                            bottom = "─",
                            none = " ",
                        },
                    },
                    icons = {
                        web_devicons = {
                            file = {
                                enable = true,
                                color = true,
                            },
                            folder = {
                                enable = true,
                                color = true,
                            },
                        },
                        git_placement = "after",
                        modified_placement = "before",
                        diagnostics_placement = "signcolumn",
                        bookmarks_placement = "signcolumn",
                        padding = " ",
                        symlink_arrow = " ➛ ",
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = true,
                            modified = true,
                            diagnostics = true,
                            bookmarks = true,
                        },
                        glyphs = {
                            default = "",
                            symlink = "",
                            bookmark = "󰆤",
                            modified = "●",
                            folder = {
                                arrow_closed = "",
                                arrow_open = "",
                                default = "",
                                open = "",
                                empty = "",
                                empty_open = "",
                                symlink = "",
                                symlink_open = "",
                            },
                            git = {
                                unstaged = "󱧔",
                                staged = "󱧘",
                                unmerged = "",
                                renamed = "",
                                untracked = "",
                                deleted = "󰮉",
                                ignored = "",
                            },
                        },
                    },
                },
                diagnostics = {
                    enable = true,
                    show_on_dirs = false,
                    show_on_open_dirs = false,
                    debounce_delay = 50,
                    severity = {
                        min = vim.diagnostic.severity.HINT,
                        max = vim.diagnostic.severity.ERROR,
                    },
                    icons = {
                        hint = '󰌵',
                        info = ' ',
                        warning = ' ',
                        error = ' ',
                    },
                },
                modified = {
                    enable = true,
                    show_on_dirs = false,
                    show_on_open_dirs = false,
                },
                filters = {
                    dotfiles = true,
                },
                trash = {
                    cmd = "trash-put",
                },
            })
        end,

    },

    {
        -- 代码大纲
        "hedyhli/outline.nvim",
        config = function()
            local outline = require("outline")

            local function toggle_outline()
                local is_outline_open = outline.is_open()
                local is_outline_focus = outline.is_focus_in_outline()

                if not is_outline_open then
                    outline.open_outline()
                else
                    if is_outline_focus then
                        outline.close_outline()
                    else
                        outline.focus_outline()
                    end
                end
            end

            vim.keymap.set("n", "<leader>o", toggle_outline, { desc = "Toggle Outline" })

            require("outline").setup {
                keymaps = {
                    show_help = '?',
                    close = 'Q',

                    goto_location = '<Cr>',
                    peek_location = 'gd',
                    goto_and_close = 'gD',
                    hover_symbol = 'gh',
                    restore_location = 'gr',
                    rename_symbol = 'gR',
                    code_actions = 'ga',

                    toggle_preview = 'p',
                    fold = '<nop>',
                    unfold = '<nop>',
                    fold_toggle = 'l',
                    fold_toggle_all = '<nop>',
                    fold_all = '<nop>',
                    unfold_all = '<nop>',
                    fold_reset = '<nop>',
                    down_and_jump = '<C-j>',
                    up_and_jump = '<C-k>',
                },
            }
        end,
    },

    {
        -- 快速打开 lazygit
        'kdheepak/lazygit.nvim',
        event = "VeryLazy",
        config = function()
            vim.g.lazygit_floating_window_scaling_factor = 0.95
            vim.g.lazygit_floating_window_winblend = 0
            vim.g.lazygit_use_neovim_remote = true
            vim.keymap.set('n', '<c-g>', ':LazyGit<CR>', { noremap = true, silent = true })
        end
    },
}

return M
