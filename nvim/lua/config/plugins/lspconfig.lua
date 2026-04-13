M = {
    'neovim/nvim-lspconfig',

    config = function()

        vim.api.nvim_create_autocmd('LspAttach', {
            desc = 'LSP actions',
            callback = function(event)
                local opts = { buffer = event.buf, noremap = true, nowait = true }

                vim.keymap.set('n', 'gj', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
                vim.keymap.set('n', 'gh', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', 'gr', function() require('fzf-lua').lsp_references() end, opts)
                vim.keymap.set('n', 'gR', vim.lsp.buf.rename, opts)
                vim.keymap.set('n', 'gt', vim.diagnostic.open_float, opts)
                vim.keymap.set({ 'n', 'v', 'x' }, '<leader>gf', function() vim.lsp.buf.format({ async = true }) end,
                    opts)
            end
        })

        vim.diagnostic.config({
            severity_sort = true,
            underline = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = ' ',
                    [vim.diagnostic.severity.WARN] = ' ',
                    [vim.diagnostic.severity.INFO] = ' ',
                    [vim.diagnostic.severity.HINT] = '󰌵',
                },
            },
            virtual_text = true,
            update_in_insert = false,
            float = true,
        })
    end
}

return M
