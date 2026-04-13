local m = { noremap = true, nowait = true }

M = {
    {
        'ibhagwan/fzf-lua',
        keys = { '<c-f>', '<leader>ef' },
        config = function()
            local fzf = require('fzf-lua')

            -- 搜索快捷键
            vim.keymap.set('n', '<leader>ef', fzf.files, m)
            vim.keymap.set('n', '<leader>eg', fzf.live_grep, m)
            vim.keymap.set('n', '<leader>er', fzf.resume, m)
            vim.keymap.set('n', '<leader>es', fzf.spell_suggest, m)
            vim.keymap.set('n', '<leader>eb', fzf.buffers, m)
            vim.keymap.set('n', '<leader>eo', fzf.oldfiles, m)
            vim.keymap.set('n', '<leader>ep', fzf.registers, m)
            vim.keymap.set('n', '<leader>et', fzf.tabs, m)

            -- fzf-lua 原有快捷键
            vim.keymap.set('n', '<c-f>', function()
                fzf.grep({ search = '', fzf_opts = { ['--layout'] = 'default' } })
            end, { noremap = true })
            vim.keymap.set('x', '<c-f>', function()
                fzf.grep_visual({ fzf_opts = { ['--layout'] = 'default' } })
            end, { noremap = true })

            fzf.setup({
                global_resume       = true,
                global_resume_query = true,
                winopts             = {
                    height     = 0.9,
                    width      = 0.9,
                    fullscreen = false,

                    preview    = {
                        layout     = 'vertical',
                        scrollbar  = 'float',
                        vertical   = 'down:45%',
                        horizontal = 'right:60%',
                        hidden     = 'nohidden',
                    },
                },
                keymap              = {
                    builtin = {
                        ['<c-p>'] = 'toggle-preview',
                    },
                    fzf = {
                        ['esc']    = 'abort',
                        ['ctrl-i'] = 'beginning-of-line',
                        ['ctrl-a'] = 'end-of-line',
                        ['ctrl-k'] = 'up',
                        ['ctrl-j'] = 'down',
                    },
                },
                defaults            = {
                    git_icons  = true,
                    file_icons = true,
                    color_icons = true,
                },
                previewers          = {
                    head = {
                        cmd  = 'head',
                        args = nil,
                    },
                    git_diff = {
                        cmd_deleted   = 'git diff --color HEAD --',
                        cmd_modified  = 'git diff --color HEAD',
                        cmd_untracked = 'git diff --color --no-index /dev/null',
                    },
                    man = {
                        cmd = 'man -c %s | col -bx',
                    },
                    builtin = {
                        syntax         = true,
                        syntax_limit_l = 0,
                        syntax_limit_b = 1024 * 1024,
                    },
                },
                files               = {
                    prompt       = 'Files❯ ',
                    multiprocess = true,
                    find_opts    = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
                    rg_opts      = '--color=never --files --hidden --follow -g \'!.git\'',
                    fd_opts      = '--color=never --type f --hidden --follow --exclude .git',
                },
                buffers             = {
                    prompt        = 'Buffers❯ ',
                    sort_lastused = true,
                    actions       = {
                        ['ctrl-d'] = { fn = require('fzf-lua.actions').buf_del, reload = true },
                    },
                },
                grep                = {
                    prompt     = 'Grep❯ ',
                    rg_opts    = '--color=never --no-heading --with-filename --line-number --column --fixed-strings --smart-case --trim',
                },
                lsp                 = {
                    prompt_postfix = '❯ ',
                },
            })
        end
    }
}

return M
