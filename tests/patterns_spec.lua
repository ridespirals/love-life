local assert = require("tests.assert")
local grid = require("src.grid")
local patterns = require("src.patterns")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

test("list returns core catalog ids", function()
  assert.equal(table.concat(patterns.list(), ","), "glider,blinker,beacon")
end)

test("get falls back to glider for unknown pattern", function()
  local pattern = patterns.get("does_not_exist")
  assert.equal(pattern.id, "glider")
end)

test("apply centers glider pattern on board", function()
  local world = grid.create(7, 7)
  patterns.apply(world, "glider")

  assert.isTrue(grid.isAlive(world, 3, 4))
  assert.isTrue(grid.isAlive(world, 4, 5))
  assert.isTrue(grid.isAlive(world, 5, 3))
  assert.isTrue(grid.isAlive(world, 5, 4))
  assert.isTrue(grid.isAlive(world, 5, 5))
end)
