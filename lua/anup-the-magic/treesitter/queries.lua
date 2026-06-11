local M = {}

function M.detect_lang(shebang)
  local ft = vim.filetype.match { contents = { shebang } }
  return ft and vim.treesitter.language.get_lang(ft) or nil
end

function M.setup()
  vim.treesitter.query.add_directive('try-detect-shebang!', function(match, _, bufnr, pred, metadata)
    local capture_id = pred[2]
    local node = match[capture_id]
    if not node then
      return
    end
    if type(node) == 'table' then
      node = node[1]
    end

    local text = vim.treesitter.get_node_text(node, bufnr)
    local shebang = text:match '^["\']*.-(#!.-)\n'
    local lang = shebang and M.detect_lang(shebang) or 'bash'

    metadata['injection.language'] = lang
  end, { force = true })
end

return M
