local assert = require("tests.assert")
local grid = require("src.grid")
local patterns = require("src.patterns")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local aliveCount = specHelper.aliveCount
local withLoveMock = specHelper.withLoveMock

test("list returns catalog ids including rle assets", function()
  assert.equal(
    table.concat(patterns.list(), ","),
    "glider,blinker,beacon,pulsar,gosper_glider_gun,lifeview"
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
