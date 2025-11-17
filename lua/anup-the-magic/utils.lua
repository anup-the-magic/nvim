---@generic T, Xs, R
---@param self (fun(T, Xs): R)
---@param a T
---@return (fun(Xs): R)
local bind1 = function(self, a)
  return function(...)
    return self(a, ...)
  end
end

local bind = function(self, ...)
  local bound = table.pack(...)

  return function(...)
    return self(table.unpack(bound), ...)
  end
end

local OLD_METATABLE = (debug.getmetatable(function() end) or {})
if vim.tbl_get(OLD_METATABLE, '__index', 'bind') then
  vim.notify('Unable to set bind on (function()end)! Perhaps renaming is necessary!', vim.log.levels.ERROR)
else
  debug.setmetatable(function() end, {
    unpack(OLD_METATABLE),
    __index = {
      bind = bind,
    },
  })
end

---@alias Command fun():nil

---@class Keybinds
---@field [string] ( Command | [ Command, string ] )

---require 'lazy.types'

---@param keybinds Keybinds
---@param opts LazyKeysBase?
local function process_keybinds(keybinds, opts)
  local ret = {}
  local i = 0

  for keybind, command in pairs(keybinds) do
    ---@type string?
    local desc
    if vim.is_callable(command) then
      command = { command, nil }
    end

    command, desc = unpack(command)
    ret[i + 1] = { keybind, command, desc, unpack(opts or {}) }
    i = i + 1
  end

  return ret
end

local function reload_vim()
  -- return vim.system({ 'kill', "-USR1 $(ps -p '" .. vim.fn.getpid() .. "' -o ppid=)" }):wait()
end

--- Creates an F-string, replacing `$variable_name` with the variable name and executing functions
--- within ${function}
--- @param module string
---@diagnostic disable-next-line: lowercase-global
function require_safe(module)
  local ok, ret = pcall(require, module)
  if not ok then
    vim.notify('Was unable to load module' .. module, vim.log.levels.WARN)
    vim.notify(vim.inspect(ret), vim.log.levels.WARN)
  end
  return ret
end

local function f_variable(orig)
  local str = orig
  str = string.gsub(str, '$(%w+)', function(n)
    return _G[n]
  end)
  return str
end

local function f_expand(orig)
  local str = orig
  str = string.gsub(str, '${(%w+)}', function(n)
    local fn, err = load(n)
    if fn == nil then
      vim.notify(
        f_variable([[Was unable to format string: $orig
      The expansion that failed: $n
      The syntax error: ]] .. err),
        vim.log.levels.ERROR
      )
      return n
    end

    return fn()
  end)

  return str
end

--- Creates an F-string, replacing `$variable_name` with the variable name and executing functions
--- within ${function}
--- @param orig string
---@diagnostic disable-next-line: lowercase-global
function f(orig)
  local str = orig
  str = f_expand(str)
  str = f_variable(str)
  return str
end

return {
  bind = bind,
  bind1 = bind1,
  process_keybinds = process_keybinds,
  reload_vim = reload_vim,
  require_safe = require_safe,
}
