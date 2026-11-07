describe "MoonScript module path fixture", ->
  it "keeps extra and existing module paths", ->
    nested = require "moonpath_nested.module"
    init = require "moonpath_package"
    choice = require "moonpath_choice"
    legacy = require "moonpath_legacy"
    lua = require "moonpath_lua"
    assert.equals "nested", nested
    assert.equals "init", init
    assert.equals "first", choice
    assert.equals "legacy", legacy
    assert.equals "lua", lua
    counts = {}
    for value in package.moonpath\gmatch "[^;]+"
      counts[value] = (counts[value] or 0) + 1
    assert.equals 1, counts["spec/fixtures/moonpath/first/?.moon"]
    assert.equals 1, counts["spec/fixtures/moonpath/second/?.moon"]
    assert.equals 2, counts["spec/fixtures/moonpath/legacy/?.moon"]
    print "MOONPATH_SENTINEL first nested init legacy lua"
