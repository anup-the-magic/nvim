-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }

  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
local plugins = {
  { 'NMAC427/guess-indent.nvim', lazy = false, opts = {} }, -- Detect tabstop and shiftwidth automatically
  {
    'OXY2DEV/markview.nvim',
    lazy = false,
    dependencies = { 'saghen/blink.cmp' },
    opts = {
      preview = {
        enable = false,
        -- modes = { 'i', 'n', 'no', 'c' },
        -- hybrid_modes = { 'i', 'n' },

        -- NOTE `true` _works_, but I haven't decided if I like it
        -- linewise_hybrid_mode = false,
      },
      markdown = {
        list_items = {
          marker_minus = { add_padding = false },
          marker_plus = { add_padding = false },
          marker_star = { add_padding = false },
        },
      },
    },
    keys = Utils.process_keybinds {
      ['<leader>tp'] = { function() vim.cmd 'Markview splitToggle' end, 'Toggle Markview' },
    },
  },
  -- TODO: do we want this still
  { 'wesQ3/vim-windowswap', lazy = false, config = function() end },

  -- TODO: the rest
  require_safe 'anup-the-magic.plugins.telescope',
  require_safe 'anup-the-magic.plugins.conform',
  require_safe 'anup-the-magic.plugins.mini_files',
  -- TODO: Also includes outline stuff
  require_safe 'anup-the-magic.plugins.lspconfig',

  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },

  -- TODO: consider upgrading this to 'kylechui/nvim-surround' or 'mini.surround' or 'vim-sandwich'
  { 'tpope/vim-surround', lazy = false, config = function() end },
  -- Subvert, among others
  { 'tpope/vim-abolish', lazy = false, config = function() end },
  { 'PeterRincker/vim-argumentative', lazy = false, config = function() end },
  { 'tpope/vim-repeat', lazy = false, config = function() end },
  {
    'junegunn/vim-easy-align',
    lazy = false,
    keys = {
      { 'ga', '<Plug>(EasyAlign)', mode = { 'n', 'x' } },
      { 'gi', '<Plug>(LiveEasyAlign)', mode = { 'n', 'x' } },
    },
    config = function() end,
  },

  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    lazy = false,
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
    keys = Utils.process_keybinds {
      -- stylua: ignore start
      -- ['[h'] = {
      --   function() require('gitsigns').nav_hunk 'prev' end,
      --   'Navigate to previous hunk',
      -- },
      -- [']h'] = {
      --   function() require('gitsigns').nav_hunk 'next' end,
      --   'Navigate to next hunk',
      -- },
      -- Doing this for now
      ['[['] = {
        function() require('gitsigns').nav_hunk 'prev' end,
        'Navigate to next hunk',
      },
      [']]'] = {
        function() require('gitsigns').nav_hunk 'next' end,
        'Navigate to previous hunk',
      },
      ['?h'] = {
        function() require('gitsigns').preview_hunk_inline() end,
        'Preview hunk inline',
      },
      -- stylua: ignore end
    },
    -- TODO: move to its own file
    config = function(_, opts)
      local gitsigns = require 'gitsigns'
      gitsigns.setup(opts)

      ---@class LoadGitParams
      ---@field use_branch boolean Use a base branch. Defaults to `false`. If true, uses gitsigns default
      ---
      ---@param params LoadGitParams|nil
      ---@return function
      local function load_git(params)
        -- lazily, for keymap callback
        return function()
          params = params or {}
          setmetatable(params, { __index = { use_default_branch = false } })

          Utils.cd_git_root()

          local include_branch = params.use_branch and require('gitsigns.config').config.base or ''

          local diff_files = Utils.stdout_lines { 'git', 'diff', '--name-only', '-M', '--relative', include_branch }
          local unstaged = Utils.stdout_lines { 'git', 'files' }
          local files = vim.trim(table.concat(vim.list_extend(diff_files, unstaged), ' '))

          if files ~= '' then vim.cmd.argadd(files) end
        end
      end

      vim.keymap.set('n', '!!', load_git { use_branch = true }, { desc = 'Open all modified files in background' })
      vim.keymap.set('n', '!l', load_git(), { desc = 'Open all currently modified files in background' })
    end,
  },
  {
    'kokusenz/deltaview.nvim',
    dependencies = { 'kokusenz/delta.lua' },
    opts = {
      keyconfig = {
        next_hunk = ']h',
        prev_hunk = '[h',
      },
    },
    setup = function(_, opts)
      local deltaview = require 'deltaview'
      deltaview.setup(opts)
      vim.cmd [[cabbrev dm DeltaMenu!]]
    end,
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      preset = 'helix',
      sort = { 'group', 'alphanum', 'mod' },
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.o.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = 'Search' },
        { '<leader>t', group = 'Toggle' },
        { '<leader>h', group = 'Git Hunk', mode = { 'n', 'v' } },
        { '<leader>gl', group = 'Language server' },
      },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  -- {
  --   'nvimtools/none-ls.nvim',
  --   dependencies = { 'neovim/nvim-lspconfig', require_safe 'anup-the-magic.plugins.mason' },
  --   opts = function(_, opts)
  --     local nls = require 'null-ls'
  --     opts.sources = opts.sources or {}
  --     table.insert(opts.sources, nls.builtins.formatting.black)
  --   end,
  -- },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'super-tab',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'normal',
      },

      completion = {
        list = {
          selection = {
            -- make snippets still work correctly, necessary because `preset = super-tab`
            preselect = function() return not require('blink.cmp').snippet_active { direction = 1 } end,
          },
        },
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        -- Default is "prefix", which only matches the bits of the word leading up to the cursor
        keyword = { range = 'full' },
        ghost_text = {
          enabled = true,
          show_without_selection = true,
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev', 'buffer' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
          buffer = {
            opts = {
              -- get all buffers, even ones like neo-tree
              -- get_bufnrs = vim.api.nvim_list_bufs

              -- or (recommended) filter to only "normal" buffers
              get_bufnrs = function()
                return vim.tbl_filter(function(bufnr) return vim.bo[bufnr].buftype == '' end, vim.api.nvim_list_bufs())
              end,
            },
          },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Highlight todo, notes, etc in comments, like so:
  -- TODO:
  -- TODO(anup):
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false,
      search = { pattern = [[(\b(KEYWORDS)(\([^\)]*\))?:)|(\> ?\[\!(KEYWORDS)] ?)]] },
      highlight = {
        pattern = { [[.*<((KEYWORDS)%(\(.{-1,}\))?):]], [[\> \[\!(KEYWORDS)\] ]] },
        comments_only = false,
      },
    },
  },

  -- TODO: We're using Mini.statusline and Mini.files
  -- Do we also want mini.input? mini.surround?
  --
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.statusline',
    lazy = false,
    opts = {
      use_icons = vim.g.have_nerd_font,
    },
    config = function(_, opts)
      local statusline = require 'mini.statusline'
      statusline.setup(opts)

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },
  --
  -- TODO: look into this further
  --       We're using vim-surround and vim-argumentative, which will probably be "good enough" for a while
  --
  -- { -- Collection of various small independent plugins/modules
  --   'echasnovski/mini.nvim',
  --   config = function()
  --     -- Better Around/Inside textobjects
  --     --
  --     -- Examples:
  --     --  - va)  - [V]isually select [A]round [)]paren
  --     --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
  --     --  - ci'  - [C]hange [I]nside [']quote
  --     -- require('mini.ai').setup { n_lines = 500 }

  --     -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --     --
  --     -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  --     -- - sd'   - [S]urround [D]elete [']quotes
  --     -- - sr)'  - [S]urround [R]eplace [)] [']
  --     -- require('mini.surround').setup()

  --     -- ... and there is more!
  --     --  Check out: https://github.com/echasnovski/mini.nvim
  --   end,
  -- },
  {
    'apple/pkl-neovim',
    lazy = true,
    ft = 'pkl',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    build = function()
      require('pkl-neovim').init()
      vim.cmd 'TSInstall pkl'
    end,
    config = function()
      local pkl_path = Utils.stdout_lines { 'which', 'pkl' }
      if pkl_path == {} then
        vim.notify('pkl binary not found!', vim.log.levels.WARN)
        return
      end

      -- Configure pkl-lsp
      vim.g.pkl_neovim = {
        pkl_cli_path = pkl_path[0],
      }
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
  },
}

require('lazy').setup(plugins, {
  ui = {
    -- requires nerd font
    icons = {},
  },
})
