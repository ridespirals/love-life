local assert = require("tests.assert")
local grid = require("src.grid")
local patterns = require("src.patterns")
local userdata = require("src.userdata")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local aliveCount = specHelper.aliveCount
local withLoveMock = specHelper.withLoveMock

test("list returns catalog ids including rle assets", function()
  assert.equal(
    table.concat(patterns.list(), ","),
    "backrake_1,beacon,blinker,bomber,circle_of_fire,copperhead,cottonmouth,diamond,fireship,glider,gosper_glider_gun,lifeview,loafer,moose_antlers,noahs_ark,pulsar,pulsar_on_pentadecathlon_i,sidecar,still_life_tagalong"
  )
end)

test("get falls back to glider for unknown pattern", function()
  local pattern = patterns.get("does_not_exist")
  assert.equal(pattern.id, "glider")
end)

test("get loads rle pattern through love.filesystem", function()
  withLoveMock({
    getInfo = function(path, kind)
      assert.equal(path, "patterns/test_rle.rle")
      assert.equal(kind, "file")
      return { type = "file" }
    end,
    read = function(path)
      assert.equal(path, "patterns/test_rle.rle")
      return "x = 3, y = 3, rule = B3/S23\nbob$2bo$3o!"
    end,
  }, function()
    local pattern = patterns.get("test_rle")
    assert.equal(pattern.id, "test_rle")
    assert.equal(pattern.rulestring, "B3/S23")
    assert.equal(#pattern.cells, 5)
  end)
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

test("stamp with empty cells clears board", function()
  local world = grid.create(5, 5)
  grid.setAlive(world, 2, 2, true)
  patterns.stamp(world, { id = "empty", name = "Empty", cells = {} })
  assert.equal(aliveCount(world), 0)
end)

test("exists distinguishes catalog ids from unknown ids", function()
  assert.isTrue(patterns.exists("glider"))
  assert.isFalse(patterns.exists("does_not_exist"))
  assert.isFalse(patterns.exists("custom"))
end)

test("fromWorld exports live cells cropped to origin", function()
  local world = grid.create(5, 5)
  grid.setAlive(world, 2, 2, true)
  grid.setAlive(world, 2, 3, true)
  grid.setAlive(world, 3, 3, true)

  local exported = patterns.fromWorld(world)
  assert.equal(#exported.cells, 3)
  assert.equal(exported.cells[1][1], 0)
  assert.equal(exported.cells[1][2], 0)
  assert.equal(exported.cells[2][1], 1)
  assert.equal(exported.cells[2][2], 0)
  assert.equal(exported.cells[3][1], 1)
  assert.equal(exported.cells[3][2], 1)
end)

test("fromWorld returns empty cells on blank board", function()
  local world = grid.create(3, 3)
  local exported = patterns.fromWorld(world)
  assert.equal(#exported.cells, 0)
end)

test("loadUser merges user patterns and protects builtins", function()
  withLoveMock({
    createDirectory = function() return true end,
    getInfo = function(path, kind)
      if path == "patterns" and (kind == "directory" or kind == nil) then
        return { type = "directory" }
      end
      if path == "patterns/my_glider.lua" and (kind == "file" or kind == nil) then
        return { type = "file" }
      end
      return nil
    end,
    getDirectoryItems = function()
      return { "my_glider.lua" }
    end,
    read = function(path)
      assert.equal(path, "patterns/my_glider.lua")
      return userdata.serialize({
        id = "my_glider",
        name = "My Glider",
        cells = { { 0, 0 }, { 1, 1 } },
      })
    end,
  }, function()
    patterns.loadUser(userdata)

    assert.isTrue(patterns.isUser("my_glider"))
    assert.isTrue(patterns.isBuiltin("glider"))
    assert.isFalse(patterns.isUser("glider"))
    assert.equal(patterns.get("my_glider").name, "My Glider")
    assert.equal(#patterns.get("my_glider").cells, 2)

    local list = table.concat(patterns.list(), ",")
    assert.isTrue(list:find("my_glider", 1, true) ~= nil)
    assert.isTrue(list:find("glider", 1, true) ~= nil)

    patterns.loadUser(nil)
  end)
end)

test("apply loads and centers pulsar from rle file", function()
  withLoveMock({
    getInfo = function(path, kind)
      local file = io.open(path, "r")
      if file then
        file:close()
        return { type = kind or "file" }
      end
      return nil
    end,
    read = function(path)
      local file = _G.assert(io.open(path, "r"))
      local text = file:read("*a")
      file:close()
      return text
    end,
  }, function()
    local world = grid.create(40, 60)
    patterns.apply(world, "pulsar")

    local count = aliveCount(world)
    local minRow, maxRow = world.rows, 1
    local minCol, maxCol = world.cols, 1
    for row = 1, world.rows do
      for col = 1, world.cols do
        if grid.isAlive(world, row, col) then
          if row < minRow then minRow = row end
          if row > maxRow then maxRow = row end
          if col < minCol then minCol = col end
          if col > maxCol then maxCol = col end
        end
      end
    end

    assert.isTrue(count > 20)
    assert.isTrue(math.abs((minRow - 1) - (world.rows - maxRow)) <= 1)
    assert.isTrue(math.abs((minCol - 1) - (world.cols - maxCol)) <= 1)
  end)
end)
