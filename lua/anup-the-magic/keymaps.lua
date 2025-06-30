-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

--  The single most important keymap
vim.keymap.set('i', 'jk', '<ESC>')

-- Clear highlights on search when pressing <Esc> or \= in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch <bar> redraw!<CR>')
vim.keymap.set('n', '<leader>=', '<cmd>nohlsearch <bar> redraw!<CR>', { desc = 'Clear the screen!' })
-- highlights all words under cursor
-- TODO: might be removable
vim.keymap.set('n', '<leader>8', [[<cmd>let @/=expand("<cword>") <bar> set hls<CR>]], { desc = 'Search under cursor' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '??', function()
  vim.diagnostic.open_float { source = true }
end, { desc = 'Show diagnostics under cursor' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--  See `:help wincmd` for a list of all window commands
--
-- NOTE: This is actually handled by vim-tmux-navigator, so no need to set it here
-- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
-- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
-- vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
-- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Editing files in the same folder
vim.keymap.set('n', '<leader>e', [[:e <C-R>=expand("%:p:h")<CR>/]], { desc = '[E]dit a file in this folder' })
vim.keymap.set('n', '<leader>r', [[:r <C-R>=expand("%:p:h")<CR>/]], { desc = '[R]ead a file in this folder' })
vim.keymap.set('n', '<leader>w', [[:w <C-R>=expand("%:p:h")<CR>/]], { desc = '[W]rite a file to this folder' })

vim.keymap.set('n', '<leader>virc', ':botright vnew $MYVIMRC<CR>', { desc = 'Edit currently loaded [VI]m[RC]' })

-- reindent the entire file
-- steals the "c" mark to return back to the current cursor
vim.keymap.set('n', 'leader>;', 'mcgg=G`c', { desc = 'Reindent this file (dumbly)' })

-- Zoom a window into its own tab with leader<z>
vim.keymap.set('n', '<leader>z', '<cmd>tabnew %<CR>', { desc = '[Z]oom in on this buffer' })

-- Tab manipulation
vim.keymap.set('n', '[t', '<cmd>tabprev<CR>', { desc = 'Go to prev tab' })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { desc = 'Go to next tab' })
