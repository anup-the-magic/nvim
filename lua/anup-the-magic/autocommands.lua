-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local groups = {
  help = vim.api.nvim_create_augroup('anup-the-magic/help', { clear = true }),
  markdown = vim.api.nvim_create_augroup('anup-the-magic/markdown', { clear = true }),
  lua = vim.api.nvim_create_augroup('anup-the-magic/lua', { clear = true }),
  highlight_yank = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
}

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = groups.highlight_yank,
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'help.vim' },
  group = groups.help,
  callback = function()
    vim.cmd 'wincmd L'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  group = groups.markdown,
  callback = function()
    vim.o.wrap = false
  end,
})

return {
  groups = groups,
}
