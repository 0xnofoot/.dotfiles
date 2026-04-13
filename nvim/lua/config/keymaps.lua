vim.g.mapleader = " "

local mode_i = { "i" }
local mode_n = { "n" }
local mode_v = { "v", "x" }
local mode_nv = { "n", "v", "x" }

local nmappings = {
    -- Movement
    { from = "J",            to = "5j",                                                  mode = mode_nv },
    { from = "K",            to = "5k",                                                  mode = mode_nv },
    { from = "<c-j>",        to = "<c-d>",                                               mode = mode_nv },
    { from = "<c-k>",        to = "<c-u>",                                               mode = mode_nv },
    { from = "<c-s-j>",      to = "G",                                                   mode = mode_nv },
    { from = "<c-s-k>",      to = "gg",                                                  mode = mode_nv },
    { from = "H",            to = "3h",                                                  mode = mode_nv },
    { from = "L",            to = "3l",                                                  mode = mode_nv },
    { from = "W",            to = "3w",                                                  mode = mode_nv },
    { from = "E",            to = "3e",                                                  mode = mode_nv },
    { from = "B",            to = "3b",                                                  mode = mode_nv },

    -- Window & splits
    { from = "zh",           to = "<Cmd>set nosplitright | vsplit | set splitright<CR>",  mode = mode_nv },
    { from = "zj",           to = "<Cmd>set splitbelow | split<CR>",                     mode = mode_nv },
    { from = "zk",           to = "<Cmd>set nosplitbelow | split | set splitbelow<CR>",  mode = mode_nv },
    { from = "zl",           to = "<Cmd>set splitright | vsplit<CR>",                    mode = mode_nv },
    { from = "<leader>k",    to = "<Cmd>wincmd k<CR>",                                   mode = mode_nv },
    { from = "<leader>j",    to = "<Cmd>wincmd j<CR>",                                   mode = mode_nv },
    { from = "<leader>h",    to = "<Cmd>wincmd h<CR>",                                   mode = mode_nv },
    { from = "<leader>l",    to = "<Cmd>wincmd l<CR>",                                   mode = mode_nv },
    { from = "<up>",         to = "<Cmd>res +5<CR>",                                      mode = mode_nv },
    { from = "<down>",       to = "<Cmd>res -5<CR>",                                      mode = mode_nv },
    { from = "<left>",       to = "<Cmd>vertical resize-5<CR>",                           mode = mode_nv },
    { from = "<right>",      to = "<Cmd>vertical resize+5<CR>",                           mode = mode_nv },
    { from = "zq",           to = "<Cmd>close<CR>",                                       mode = mode_nv },
    { from = "zQ",           to = "<Cmd>on<CR>",                                          mode = mode_nv },

    -- Buffer management
    { from = "tt",           to = "<Cmd>enew<CR>",                                        mode = mode_nv },
    { from = "<c-h>",        to = "<Cmd>bprevious<CR>",                                   mode = mode_nv },
    { from = "<c-l>",        to = "<Cmd>bnext<CR>",                                       mode = mode_nv },

    -- Tab management
    { from = "tb",           to = "<Cmd>tabe<CR>",                                        mode = mode_nv },
    { from = "th",           to = "<Cmd>-tabnext<CR>",                                    mode = mode_nv },
    { from = "tl",           to = "<Cmd>+tabnext<CR>",                                    mode = mode_nv },
    { from = "tq",           to = "<Cmd>tabclose<CR>",                                    mode = mode_nv },

    -- Useful actions
    { from = "<c-c>",        to = "<nop>",                                               mode = mode_nv },
    { from = "<c-w>",        to = "<nop>",                                               mode = mode_nv },
    { from = "q",            to = "<nop>",                                               mode = mode_nv },
    { from = "Q",            to = "<nop>",                                               mode = mode_nv },

    { from = ";",            to = ":",                                                   mode = mode_nv },
    { from = "S",            to = "<Cmd>write<CR>",                                       mode = mode_nv },
    { from = "Q",            to = vim.g.quitNvim,                                        mode = mode_nv },

    { from = "`",            to = "~",                                                   mode = mode_nv },
    { from = "'",            to = "%",                                                   mode = mode_nv },
    { from = ",",            to = "0",                                                   mode = mode_nv },
    { from = ".",            to = "$",                                                   mode = mode_nv },

    { from = "v'",           to = "v%",                                                  mode = mode_n },
    { from = "d'",           to = "d%",                                                  mode = mode_n },
    { from = "c'",           to = "c%",                                                  mode = mode_n },

    { from = "v,",           to = "v0",                                                  mode = mode_n },
    { from = "d,",           to = "d0",                                                  mode = mode_n },
    { from = "c,",           to = "c0",                                                  mode = mode_n },

    { from = "v.",           to = "v$h",                                                 mode = mode_n },
    { from = "d.",           to = "v$hd",                                                mode = mode_n },
    { from = "c.",           to = "c$",                                                  mode = mode_n },

    { from = "U",            to = "<c-r>",                                               mode = mode_n },
    { from = "<leader><cr>", to = "<Cmd>nohlsearch<CR>",                                  mode = mode_nv },

    { from = "u",            to = "<nop>",                                               mode = mode_v },
    { from = "U",            to = "<nop>",                                               mode = mode_v },
    { from = "<leader>u",    to = "u",                                                   mode = mode_v },
    { from = "<leader>U",    to = "U",                                                   mode = mode_v },
}

for _, mapping in ipairs(nmappings) do
    vim.keymap.set(mapping.mode or "n", mapping.from, mapping.to, { noremap = true })
end

-- 注释快捷键（使用 Neovim 内置 gc/gcc）
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true })
vim.keymap.set('v', '<C-_>', 'gc', { remap = true })
vim.keymap.set('i', '<C-_>', '<Esc>gcca', { remap = true })
