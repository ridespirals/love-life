local assert = require("tests.assert")
local grid = require("src.grid")
local rules = require("src.rules")

local conway = rules.get("conway")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

local function aliveCount(world)
  local count = 0
  for row = 1, world.rows do
    for col = 1, world.cols do
      if world.current[row][col] then
        count = count + 1
      end
    end
  end
  return count
end

test("empty board stays empty after computeNext", function()
  local world = grid.create(3, 3)
  grid.computeNext(world, conway)
  assert.equal(aliveCount(world), 0)
end)

test("dead cell with exactly three neighbors is born", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 1, 1, true)
  grid.setAlive(world, 1, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.computeNext(world, conway)
  assert.isTrue(world.next[2][2])
end)

test("live cell with fewer than two neighbors dies", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 2, 2, true)
  grid.computeNext(world, conway)
  assert.isFalse(world.next[2][2])
end)

test("live cell with four or more neighbors dies", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 2, 2, true)
  grid.setAlive(world, 1, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.setAlive(world, 2, 3, true)
  grid.setAlive(world, 3, 2, true)
  grid.computeNext(world, conway)
  assert.isFalse(world.next[2][2])
end)

test("live cell with two or three neighbors survives", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 2, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.setAlive(world, 1, 2, true)
  grid.computeNext(world, conway)
  assert.isTrue(world.next[2][2])
end)

test("toroidal wrap counts vertical edge neighbors", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 3, 1, true)
  assert.equal(grid.countNeighbors(world, 1, 1), 1)
end)

test("blinker oscillates with period two", function()
  local world = grid.create(5, 5)
  grid.setAlive(world, 3, 2, true)
  grid.setAlive(world, 3, 3, true)
  grid.setAlive(world, 3, 4, true)

  grid.computeNext(world, conway)
  assert.isFalse(world.next[3][2])
  assert.isTrue(world.next[2][3])
  assert.isTrue(world.next[3][3])
  assert.isTrue(world.next[4][3])
  assert.isFalse(world.next[3][4])

  grid.step(world, conway)
  assert.isTrue(grid.isAlive(world, 2, 3))
  assert.isTrue(grid.isAlive(world, 3, 3))
  assert.isTrue(grid.isAlive(world, 4, 3))
  assert.isFalse(grid.isAlive(world, 3, 2))
  assert.isFalse(grid.isAlive(world, 3, 4))

  grid.step(world, conway)
  assert.isTrue(grid.isAlive(world, 3, 2))
  assert.isTrue(grid.isAlive(world, 3, 3))
  assert.isTrue(grid.isAlive(world, 3, 4))
  assert.isFalse(grid.isAlive(world, 2, 3))
  assert.isFalse(grid.isAlive(world, 4, 3))
end)

test("computeNext leaves current unchanged", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 2, 2, true)
  local before = world.current[2][2]
  grid.computeNext(world, conway)
  assert.equal(world.current[2][2], before)
  assert.isFalse(world.next[2][2])
end)
