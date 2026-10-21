describe('busted.fasttrace', function()
  local fasttrace = require 'busted.fasttrace'

  -- capture compares both producers from the same stack depth, mirroring how
  -- getTrace calls them: trimmed(1) and traceback('', 1) both start at the same frame; the stock text is then cut like core's trimTrace.
  
  local function capture(exact)
    -- both producers must run on the same source line: the shared frame's
    -- currentline is the call site
    local fast, full = fasttrace.trimmed(1, exact), debug.traceback('', 1)
    local index = full:find('\n%s*%[C]')
    return fast, full:sub(1, index)
  end

  it('reproduces the stock traceback for the frames trimTrace keeps', function()
    local function level3() return capture(true) end
    local function level2() return level3() end
    local function level1() return level2() end
    local fast, stock = level1()
    assert.are.equal(stock, fast)
  end)

  it('marks tail calls like luaL_traceback does', function()
    local fast, stock = capture(true)
    assert.are.equal(stock, fast)
  end)

  it('returns nil when no C frame appears within the printed window', function()
    -- a Lua-only recursion deeper than the unskipped window cannot guarantee
    -- an exact match, so trimmed must decline rather than approximate
    local result
    local function recurse(n)
      if n == 0 then result = fasttrace.trimmed(1, false) return end
      recurse(n - 1)
    end
    recurse(25)
    assert.is_nil(result)
  end)

  it('keeps the traceback header and frame source positions', function()
    local function inner() return fasttrace.trimmed(1, false) end
    local trace = inner()
    assert.is_truthy(trace:match('^\nstack traceback:'))
    assert.is_truthy(trace:find('fasttrace_spec.lua:%d+: in', 1))
  end)
end)
