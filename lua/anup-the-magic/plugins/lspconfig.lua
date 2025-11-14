-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
---@param client vim.lsp.Client
---@param method vim.lsp.protocol.Method
---@param bufnr? integer some lsp support methods only in specific files
---@return boolean
local function client_supports_method(client, method, bufnr)
  if vim.fn.has 'nvim-0.12' == 1 then
    vim.health.warn 'Remove client_supports_method override since latest vim will have it'
  end
  if vim.fn.has 'nvim-0.11' == 1 then
    return client:supports_method(method, bufnr)
  else
    ---@diagnostic disable-next-line:param-type-mismatch
    return client.supports_method(method, { bufnr = bufnr })
  end
end

local groups = {
  lsp_highlight = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false }),
}

local function lsp_detach(event)
  vim.lsp.buf.clear_references()
  vim.api.nvim_clear_autocmds { group = groups.lsp_highlight, buffer = event.buf }
end

local function lsp_attach(event)
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  local telescope = require 'telescope.builtin'

  map('glr', vim.lsp.buf.rename, 'Rename')

  map('gla', vim.lsp.buf.code_action, 'Goto Code Action', { 'n', 'x' })
  map('gltr', telescope.lsp_references, 'Goto References')
  map('glti', telescope.lsp_implementations, 'Goto Implementation')
  map('gltd', telescope.lsp_definitions, 'Goto Definition')
  map('gltD', vim.lsp.buf.declaration, 'Goto Declaration (eg, *.h)')
  map('gltt', telescope.lsp_type_definitions, 'Goto Type Definition')

  map('<leader>sls', telescope.lsp_document_symbols, 'Open Document Symbols')
  map('<leader>slS', telescope.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  --    See `:help CursorHold` for information about when this is executed
  --
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = groups.lsp_highlight,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = groups.lsp_highlight,
      callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = lsp_detach,
    })
  end

  -- The following code creates a keymap to toggle inlay hints in your
  -- code, if the language server you are using supports them
  --
  -- This may be unwanted, since they displace some of your code
  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
    map(
      '<leader>th',
      function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end,
      'Toggle Inlay Hints'
    )
  end
end

return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    -- TODO
    require 'anup-the-magic.plugins.telescope',
    require 'anup-the-magic.plugins.mason',

    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by blink.cmp
    'saghen/blink.cmp',

    -- Gives you a file overview with :Navbuddy
    -- TODO: Decide which of these we want to keep
    {
      'SmiteshP/nvim-navbuddy',
      dependencies = {
        'SmiteshP/nvim-navic',
        'MunifTanjim/nui.nvim',
      },
      lazy = true,
      cmd = { 'Navbuddy' },
      keys = { 'gO', '<cmd>Navbuddy<CR>' },
      opts = { lsp = { auto_attach = true } },
    },
    {
      'stevearc/aerial.nvim',
      lazy = false, -- Can probably go through commands and list all, here
      keys = { -- Example mapping to toggle outline
        { '<leader>o', '<cmd>AerialOpen<CR>', desc = 'Open outline' },
      },
      opts = {},
      -- Optional dependencies
      dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    },
    {
      'seblyng/roslyn.nvim',
      ft = 'cs',
      ---@module 'roslyn.config'
      ---@type RoslynNvimConfig
      opts = {
        choose_target = function(target)
          print 'finding'

          return vim.iter(target):find(function(item)
            print('Finding solution: ' .. item)

            if string.match(item, 'Vim.sln') then return item end
          end)
        end,
        debug = true,
        silent = false,
      },
    },
    -- {
    --   'hedyhli/outline.nvim',
    --   lazy = true,
    --   cmd = { 'Outline', 'OutlineOpen' },
    --   keys = { -- Example mapping to toggle outline
    --     { '<leader>o', '<cmd>Outline<CR>', desc = 'Toggle outline' },
    --   },
    --   opts = {},
    -- },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = lsp_attach,
    })

    -- Diagnostic Config
    -- See :help vim.diagnostic.Opts
    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    }

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      -- clangd = {},
      -- gopls = {},
      -- pyright = {},
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`ts_ls`) will work just fine
      -- ts_ls = {},
      --

      lua_ls = {
        -- cmd = { ... },
        -- filetypes = { ... },
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
      -- Python LSP
      pyright = {},
      -- Python formatter
      black = {},
    }

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in this menu.
    --
    -- `mason` had to be setup earlier: to configure its options see the
    -- `dependencies` table for `nvim-lspconfig` above.
    --
    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
      automatic_installation = false,
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for ts_ls)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }

    -- See "https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#roslyn_ls" for installation, roslyn sucks
    local function get_roslyn_base_cmd()
      local cur_dir = vim.uv.cwd()
      if not cur_dir then
        vim.notify('Err:cwd:' .. cur_dir, vim.log.levels.ERROR)
        return nil
      end

      if string.match(cur_dir, '^/mnt/') then
        return {
          'dotnet',
          '~/.local/lib/roslyn/content/LanguageServer/linux-x64/Microsoft.CodeAnalysis.LanguageServer.dll',
        }
      else
        -- Generate csproj on linux with
        -- (alias unity to project-specific unity) (add symlink to ._tmp/bin)
        -- `unity -batchmode -nographics -logFile - -executeMethod UnityEditor.SyncVS.SyncSolution -projectPath . -quit`
        -- See regenerate-sln
        return {
          'dotnet',
          '~/.local/lib/roslyn/content/LanguageServer/linux-x64/Microsoft.CodeAnalysis.LanguageServer.dll',
        }
      end
    end

    local roslyn = get_roslyn_base_cmd()
    if roslyn then
      -- Use roslyn_ls for the base config, but roslyn is provided by seblyng/roslyn.nvim
      vim.lsp.enable 'roslyn'
      vim.lsp.config('roslyn', {
        cmd = vim.list_extend(roslyn, {
          '--logLevel=Trace', -- this property is required by the server
          -- '--logLevel=Information', -- this property is required by the server
          '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
          '--stdio',
        }),
        filetypes = { 'cs' },
        on_error = function(_, err) vim.notify(err, vim.log.levels.ERROR) end,
      })
    end

    vim.lsp.enable 'vtsls'
    vim.lsp.config('vtsls', {
      filetypes = {},
    })
    vim.lsp.enable 'ts_ls'
    vim.lsp.config('ts_ls', {
      cmd = { 'npx', 'typescript-language-server', '--stdio' },
    })

    vim.lsp.enable 'clangd'
    vim.lsp.config('clangd', { cmd = { 'clangd-20' } })
  end,
}
