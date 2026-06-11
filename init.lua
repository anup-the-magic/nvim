-- vim.lsp.set_log_level 'debug'

-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

local ok, utils = pcall(require, 'anup-the-magic.utils')
if not ok then vim.notify("Coudln't load anup-the-magic.utils", vim.log.levels.ERROR) end

Utils = utils
require_safe 'anup-the-magic.autocommands'
require_safe 'anup-the-magic.options'
require_safe 'anup-the-magic.keymaps'
require_safe 'anup-the-magic.plugins'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
