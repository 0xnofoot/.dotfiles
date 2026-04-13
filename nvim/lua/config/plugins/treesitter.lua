M = {
    'nvim-treesitter/nvim-treesitter',

    branch = 'main',
    lazy = false,
    priority = 1000,
    build = ':TSUpdate',

    config = function()
        vim.opt.smartindent = false

        require('nvim-treesitter').install {
            'c', 'lua', 'vim', 'vimdoc', 'query', 'python', 'bash', 'objc', 'rust', 'dart',
            'markdown', 'markdown_inline',
        }

        vim.api.nvim_create_autocmd('FileType', {
            callback = function(ev)
                local buf = ev.buf
                local full_filename = vim.api.nvim_buf_get_name(buf)

                local ok, stats = pcall(vim.uv.fs_stat, full_filename)
                if ok and stats then
                    if stats.size > 100 * 1024 then return end
                    if string.match(string.lower(full_filename), "%.log$") then return end
                end

                pcall(vim.treesitter.start)

                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })

        vim.treesitter.language.register('objc', 'objcpp')
    end,
}

return M
