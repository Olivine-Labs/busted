-- Lua-side reproduction of luaL_traceback (Lua 5.2+ lauxlib.c) for the frames
-- busted's trimTrace keeps: from `level` up to (excluding) the first C frame.
-- luaL_traceback's pushglobalfuncname scans all of package.loaded for every
-- stack frame to find a global name; with many modules loaded and one
-- getTrace call per describe/it, that scan dominates suite loading time,
-- while trimTrace discards every frame past the first C frame anyway.
--
-- Returns the trimmed text, or nil when the exact result cannot be guaranteed
-- (no C frame within the first 10 levels luaL_traceback prints unskipped).
local getinfo, loaded = debug.getinfo, package.loaded
local format, concat = string.format, table.concat
local M = {}

local function globalname(fn, exact)
  if not exact then return nil end
  for k, v in next, loaded do
    if type(k) == 'string' then
      if rawequal(v, fn) then return k end
      if type(v) == 'table' then
        for k2, v2 in next, v do
          if type(k2) == 'string' and rawequal(v2, fn) then
            local name = k .. '.' .. k2
            if name:sub(1, 3) == '_G.' then name = name:sub(4) end
            return name
          end
        end
      end
    end
  end
end

-- level is relative to the caller of M.trimmed (same convention as debug.traceback)
function M.trimmed(level, exact)
  level = level + 1
  local parts, n = { '\nstack traceback:' }, 1
  for printed = 1, 10 do
    local ar = getinfo(level, 'Slntf')
    if not ar then return concat(parts) end      -- whole stack printed, no C frame
    if ar.what == 'C' then return concat(parts) .. '\n' end
    local where = ar.currentline > 0 and format('\n\t%s:%d: in ', ar.short_src, ar.currentline)
                                      or format('\n\t%s: in ', ar.short_src)
    local g = (exact or ar.what == 'main') and globalname(ar.func, true) or nil
    local fname
    if g then fname = format("function '%s'", g)
    elseif ar.namewhat ~= '' then fname = format("%s '%s'", ar.namewhat, ar.name)
    elseif ar.what == 'main' then fname = 'main chunk'
    else fname = format('function <%s:%d>', ar.short_src, ar.linedefined) end
    n = n + 1; parts[n] = where .. fname
    if ar.istailcall then n = n + 1; parts[n] = '\n\t(...tail calls...)' end
    level = level + 1
  end
  return nil
end
return M
