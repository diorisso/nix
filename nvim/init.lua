vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"
vim.opt.signcolumn = "yes"
vim.opt.winborder = "rounded"

vim.g.mapleader = " "

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

vim.keymap.set('n', '<leader>g', vim.diagnostic.open_float)
vim.keymap.set('n', '<C-.>', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>sf', ":Pick files<CR>")
vim.keymap.set('n', '<leader>w', "::Pick files<CR>")
vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', { noremap = true, silent = true })

vim.opt.list = true
vim.opt.listchars = {
  tab = '→ ',
  nbsp = '␣',
  trail = '•',
  extends = '⟩',
  precedes = '⟨',
  space = '•',
}

vim.pack.add({
  "https://github.com/vague-theme/vague.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/hrsh7th/nvim-cmp",
  "https://github.com/hrsh7th/cmp-nvim-lsp",
  "https://github.com/hrsh7th/cmp-omni",
  "https://github.com/nvim-mini/mini.pick",
  "https://github.com/nvim-mini/mini.pairs"
})

require("mini.pairs").setup()
require("mini.pick").setup()
require("vague").setup({
  transparent = true,
})

local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'omni' },
  },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
})

vim.lsp.enable({ "lua_ls", "csharp_ls" })

vim.cmd(":hi statusline guibg=NONE")
vim.cmd("colorscheme vague")
