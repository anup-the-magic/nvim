local utils = require 'anup-the-magic.utils'

local open_split = function(direction)
  return function()
    -- Make new window and set it as target
    local cur_target = MiniFiles.get_explorer_state().target_window
    local new_target = vim.api.nvim_win_call(cur_target, function()
      vim.cmd(direction .. ' split')
      return vim.api.nvim_get_current_win()
    end)

    MiniFiles.set_target_window(new_target)

    -- TODO: Include a helper for "preview opening" and "opening"
    MiniFiles.go_in { close_on_file = true }
  end
end
local splits = {
  vertical = open_split 'belowright horizontal',
  horizontal = open_split 'belowright vertical',
  tab = open_split 'tab',
}

---@param keymaps { horizontal: string, vertical: string, tab: string }
local function setup_split_opening(keymaps)
  local map_split = function(buf_id, lhs, direction)
    local rhs = function()
      -- Make new window and set it as target
      local cur_target = MiniFiles.get_explorer_state().target_window
      local new_target = vim.api.nvim_win_call(cur_target, function()
        vim.cmd(direction .. ' split')
        return vim.api.nvim_get_current_win()
      end)

      MiniFiles.set_target_window(new_target)

      -- TODO: Include a helper for "preview opening" and "opening"
      MiniFiles.go_in { close_on_file = true }
    end

    -- Adding `desc` will result into `show_help` entries
    local desc = 'Split ' .. direction
    vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id
      -- Tweak keys to your liking
      map_split(buf_id, keymaps.horizontal, 'belowright horizontal')
      map_split(buf_id, keymaps.vertical, 'belowright vertical')
      map_split(buf_id, keymaps.tab, 'tab')
    end,
  })
end

---@param entries { path: string }
local function gitignore_sort(entries)
  -- technically can filter entries here too, and checking gitignore for _every entry individually_
  -- like I would have to in `content.filter` above is too slow. Here we can give it _all_ the entries
  -- at once, which is much more performant.

  -- stylua: ignore start
  ---@type string[]
  local all_files = vim.tbl_map(function(entry) return entry.path end, entries)
  -- stylua: ignore end

  local output_lines = {}
  local job_id = vim.fn.jobstart({ 'git', 'check-ignore', '--stdin' }, {
    stdout_buffered = true,
    on_stdout = function(_, data) output_lines = data end,
  })

  -- command failed to run
  if job_id < 1 then return require('mini.files').default_sort(entries) end

  -- send paths via STDIN
  local all_paths = table.concat(all_files, '\n')
  vim.fn.chansend(job_id, all_paths)
  vim.fn.chanclose(job_id, 'stdin')
  vim.fn.jobwait { job_id }
  return require('mini.files').default_sort(
    vim.tbl_filter(function(entry) return not vim.tbl_contains(output_lines, entry.path) end, entries)
  )
end

local function toggle_preview()
  local config = vim.b.minifiles_config
  local old
  if config == nil then
    old = MiniFiles.config.windows.preview
  else
    old = config.windows.preview
  end

  config = config or {}
  config.windows = config.windows or { preview = not old }
end
---@param keymaps { toggle: string }
local function setup_toggle_preview(keymaps)
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id
      vim.keymap.set('n', keymaps.toggle, toggle_preview, { buffer = buf_id, desc = 'Toggle preview' })
    end,
  })
end

local state = {
  is_open = false,
}

local function config(_, opts)
  require('mini.files').setup(opts)

  local open_file = function() MiniFiles.go_in { close_on_file = true } end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id

      -- No idea why these won't work on opts.keys
      vim.keymap.set('n', '<CR>', open_file, { buffer = buf_id, desc = 'Select' })
      vim.keymap.set('n', '<ESC>', MiniFiles.close, { buffer = buf_id, desc = 'Close' })
    end,
  })

  -- stylua: ignore start
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesExplorerOpen',
    callback = function() state.is_open = true end,
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesExplorerClose',
    callback = function() state.is_open = false end,
  })
  -- stylua: ignore end

  setup_toggle_preview { toggle = 'gp' }

  require('which-key').add {
    'g',
    group = 'mini.files',
    cond = function() return vim.bo.filetype == 'minifiles' and state.is_open end,
  }
end

-- stylua: ignore start
local dotfiles = {
  ---@diagnostic disable-next-line:unused-local
  show = function(fs_entry) return true end,
  hide = function(fs_entry) return not vim.startswith(fs_entry.name, '.') end,
  showing = true,
}
-- stylua: ignore end

---@param fs_entry fs_entry
dotfiles.filter = function(fs_entry) return (dotfiles.showing and dotfiles.show or dotfiles.hide)(fs_entry) end

ToggleHiddenFiles = function() dotfiles.showing = not dotfiles.showing end

---@param fs_entry fs_entry
local function get_filters(fs_entry)
-- stylua: ignore start
  return {
    dotfiles   = dotfiles.filter(fs_entry),
    meta_files = not vim.endswith(fs_entry.name, 'meta'),
  }
  -- stylua: ignore end
end

---@param fs_entry fs_entry
---@return boolean
local function filter_files(fs_entry)
  local filters = get_filters(fs_entry)

  return filters.dotfiles and filters.meta_files
end

function print_filters()
  local fs = MiniFiles.get_fs_entry() or {}
  local ret = get_filters(fs)
  print(vim.inspect(ret))
  return { ret = ret, fs = fs }
end

-- stylua: ignore start
local commands = {
  toggle_dotfiles = function()
    dotfiles.showing = not dotfiles.showing
    MiniFiles.refresh { content = { filter = filter_files } }
  end,

  open_file_dir = function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end,

  open_split = {
    horizontal = function() open_split('belowright horizontal') end,
    vertical   = function() open_split('belowright vertical'  ) end,
    tab        = function() open_split('tab'                  ) end,
  },

  print_filter = print_filters,

  -- cd  = function() vim.uv.chdir(MiniFiles.) end
  -- pwd = function() vim.uv.chdir(MiniFiles.) end
}
-- stylua: ignore end

-- stylua: ignore start
local mini_keybinds = {
  ['g.' ] = { commands.toggle_dotfiles, 'Toggle hiding and showing dotfiles' },
  ['gp' ] = { commands.toggle_preview, 'Toggle the preview pane' },
  ['gs' ] = { commands.open_split.horizontal, 'Open file in new horizontal split' },
  ['gv' ] = { commands.open_split.vertical, 'Open file in new vertical split' },
  ['gt' ] = { commands.open_split.tab, 'Open file in new tab' },
  ['g!' ] = { commands.print_filter, 'Print the current filter output for this file' },
  -- ['gcd'] = { commands.cd, 'Change current working directory to' },
  -- ['pwd'] = { commands.go_to_pwd, 'Go to current working directory' },
}

-- stylua: ignore end

local global_keybinds = {
  ['<leader>e'] = { commands.open_file_dir, 'Open the directory for this file' },
}
-- stylua: ignore end

return {
  'echasnovski/mini.files',
  dependencies = { 'folke/which-key.nvim' },
  version = false,
  -- Necessary for "vim ."
  lazy = false,
  keys = {
    unpack(utils.process_keybinds(mini_keybinds, { ft = 'minifiles' })),
    unpack(utils.process_keybinds(global_keybinds)),
  },

  -- cf {MiniFiles.config}
  opts = {
    windows = { preview = false, width_preview = 80 },
    sort = gitignore_sort,
    content = {
      -- filter = dotfiles.filter,
      filter = filter_files,
    },
  },
  config = config,
}
