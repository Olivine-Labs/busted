local has_moon = pcall(require, 'moonscript')
local describe_moon = has_moon and describe or pending

describe_moon('MoonScript extra module paths', function()
  local paths = 'spec/fixtures/moonpath/first/?.lua;' ..
    'spec/fixtures/moonpath/first/?/init.lua;' ..
    'spec/fixtures/moonpath/second/?.lua;' ..
    'spec/fixtures/moonpath/first/?.lua'
  local command = [[lua -e "package.moonpath='spec/fixtures/moonpath/legacy/?.moon;spec/fixtures/moonpath/legacy/?.moon;spec/fixtures/moonpath/second/?.moon'"]] ..
    ' bin/busted --output=plainTerminal --pattern=cl_moonpath.moon$ '

  local function check(option)
    local process, err = io.popen(command .. option .. ' 2>&1', 'r')
    assert.is_not_nil(process, err)
    local output = process:read('*a')
    local success, reason, code = process:close()
    if type(success) == 'number' then
      assert.equals(0, success, output)
    else
      assert.is_true(success, output)
      if code ~= nil then
        assert.equals('exit', reason, output)
        assert.equals(0, code, output)
      end
    end
    assert.matches('MOONPATH_SENTINEL first nested init legacy lua', output, 1, true)
    assert.matches('\n1 success / 0 failures / 0 errors / 0 pending :', output, 1, true)
  end

  it('uses --lpath for nested and init modules without losing custom paths', function()
    check('--lpath="' .. paths .. '"')
  end)

  it('uses -m with the same path order and no duplicate MoonScript templates', function()
    check('-m "' .. paths .. '"')
  end)

  it('uses a .busted profile for the same MoonScript module lookup', function()
    check('--config-file=spec/fixtures/moonpath/.busted')
  end)
end)
