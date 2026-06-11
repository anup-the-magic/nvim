-- Autoformat

local tsformatters = { 'prettierd', 'prettier', lsp_fallback = true, lsp_format = 'fallback' }
local post_save_formatters = {
  python = { 'black', 'ruff' },
}

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre', 'BufWritePost' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function() require('conform').format { async = true, lsp_format = 'fallback' } end,
      mode = '',
      desc = 'Format buffer',
    },
    {
      '<leader>tf',
      function()
        -- If autoformat is currently disabled for this buffer,
        -- then enable it, otherwise disable it
        if vim.b.disable_autoformat then
          vim.cmd 'FormatEnable'
          vim.notify 'Enabled autoformat for current buffer'
        else
          vim.cmd 'FormatDisable!'
          vim.notify 'Disabled autoformat for current buffer'
        end
      end,
      desc = 'Toggle autoformat for current buffer',
    },
    {
      '<leader>tF',
      function()
        -- If autoformat is currently disabled globally,
        -- then enable it globally, otherwise disable it globally
        if vim.g.disable_autoformat then
          vim.cmd 'FormatEnable'
          vim.notify 'Enabled autoformat globally'
        else
          vim.cmd 'FormatDisable'
          vim.notify 'Disabled autoformat globally'
        end
      end,
      desc = 'Toggle autoformat globally',
    },
  },
  opts = {
    notify_on_error = true,
    default_format_opts = {
      lsp_format = 'fallback',
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      if post_save_formatters[vim.bo[bufnr].filetype] then return end

      local should_lsp_fallback = {
        c = false,
        cpp = false,
        cs = false,
      }

      return {
        timeout_ms = 500,
        lsp_fallback = not should_lsp_fallback[vim.bo[bufnr].filetype],
      }
    end,
    format_after_save = function(bufnr)
      if not post_save_formatters[vim.bo[bufnr].filetype] then return end

      return post_save_formatters[vim.bo[bufnr].filetype]
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      cuda = { 'clang_format' },
      cmake = { 'cmake_format' },
      css = tsformatters,
      markdown = tsformatters,
      javascript = tsformatters,
      typescript = tsformatters,
      typescriptreact = tsformatters,
      ['*'] = { 'trim_whitespace' },
      -- cs = { 'roslyn', 'csharpier', stop_after_first = true },
    },
  },
  config = function(_, opts)
    require('conform').setup(opts)

    local conform_group = vim.api.nvim_create_augroup('anup-the-magic/conform', { clear = true })
    vim.g.disable_autoformat = false
    vim.api.nvim_create_autocmd('FileType', {
      group = conform_group,
      pattern = 'cs',
      callback = function(au_opts)
        print('Disabling autoformat for buffer ' .. au_opts.buf)
        vim.b[au_opts.buf].disable_autoformat = true
      end,
    })

    vim.api.nvim_create_user_command('FormatDisable', function(args)
      -- :FormatDisable disables autoformat for this buffer only
      -- :FormatDisable! disables autoformat globally
      local disable = args.bang and vim.g or vim.b
      disable.diable_autoformat = true
    end, {
      desc = 'Disable autoformat-on-save',
      bang = true, -- allows the ! variant
    })

    vim.api.nvim_create_user_command('FormatEnable', function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = 'Re-enable autoformat-on-save',
    })
  end,
}
