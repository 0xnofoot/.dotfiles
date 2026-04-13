local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- 自定义插件配置
require("lazy").setup({

    -- 主题样式配置
    require("config.plugins.style"),

    -- 编辑优化
    -- 一系列编辑优化插件
    require("config.plugins.editor"),

    -- 查找
    require("config.plugins.search"),

    -- lsp 配置
    -- lsp 主配置
    require("config.plugins.lspconfig"),
    -- lsp 自动补全
    require("config.plugins.autocomplete"),

    -- treesitter 语法分析
    require("config.plugins.treesitter"),

})
