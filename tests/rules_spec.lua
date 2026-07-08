local assert = require("tests.assert")
local grid = require("src.grid")
local rules = require("src.rules")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

test("parse B3/S23 yields birth on 3 and survival on 2 or 3", function()
  local parsed = rules.parse("B3/S23")
  assert.isTrue(parsed.birth[3])
  assert.isFalse(parsed.birth[2])
  assert.isTrue(parsed.survival[2])
  assert.isTrue(parsed.survival[3])
  assert.isFalse(parsed.survival[4])
end)

test("parse B3/S234 yields survival on 2, 3, or 4", function()
  local parsed = rules.parse("B3/S234")
  assert.isTrue(parsed.birth[3])
  assert.isTrue(parsed.survival[2])
  assert.isTrue(parsed.survival[3])
  assert.isTrue(parsed.survival[4])
  assert.isFalse(parsed.survival[5])
end)

test("parse rejects invalid rulestrings", function()
  local ok = pcall(rules.parse, "invalid")
  assert.isFalse(ok)
end)

test("get returns named presets", function()
  local conway = rules.get("conway")
  assert.equal(conway.name, "conway")
  assert.equal(conway.rulestring, "B3/S23")

  local antColony = rules.get("ant_colony")
  assert.equal(antColony.name, "ant_colony")
  assert.equal(antColony.rulestring, "B3/S234")
end)

test("get falls back to conway for unknown names", function()
  local fallback = rules.get("unknown")
  assert.equal(fallback.name, "conway")
end)

test("list returns sorted preset names", function()
  assert.equal(table.concat(rules.list(), ","), "ant_colony,conway")
end)

test("conway kills live cell with four neighbors", function()
  local world = grid.create(3, 3)
  local conway = rules.get("conway")

  grid.setAlive(world, 2, 2, true)
  grid.setAlive(world, 1, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.setAlive(world, 2, 3, true)
  grid.setAlive(world, 3, 2, true)

  grid.computeNext(world, conway)
  assert.isFalse(world.next[2][2])
end)

test("ant colony survives live cell with four neighbors", function()
  local world = grid.create(3, 3)
  local antColony = rules.get("ant_colony")

  grid.setAlive(world, 2, 2, true)
  grid.setAlive(world, 1, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.setAlive(world, 2, 3, true)
  grid.setAlive(world, 3, 2, true)

  grid.computeNext(world, antColony)
  assert.isTrue(world.next[2][2])
end)
