local assert = require("tests.assert")
local board = require("src.input.board")
local grid = require("src.grid")
local specHelper = require("tests.spec_helper")
local test = specHelper.test

local layout = {
  offsetX = 10,
  offsetY = 20,
  tileSize = 24,
}

test("screenToCell maps pixels to 1-based grid coordinates", function()
  local world = grid.create(5, 5)
  local row, col = board.screenToCell(34, 44, layout, world)
  assert.equal(row, 2)
  assert.equal(col, 2)
end)

test("screenToCell returns nil outside the board", function()
  local world = grid.create(5, 5)
  assert.equal(board.screenToCell(0, 0, layout, world), nil)
  assert.equal(board.screenToCell(200, 200, layout, world), nil)
end)

test("beginStroke toggles alive on left click", function()
  local world = grid.create(5, 5)
  local state = board.create()
  board.beginStroke(state, world, 2, 2, 1)
  assert.isTrue(grid.isAlive(world, 2, 2))
  board.endStroke(state)
end)

test("beginStroke paints dead on right click", function()
  local world = grid.create(5, 5)
  grid.setAlive(world, 2, 2, true)
  local state = board.create()
  board.beginStroke(state, world, 2, 2, 2)
  assert.isFalse(grid.isAlive(world, 2, 2))
  board.endStroke(state)
end)

test("continueStroke fills gaps along drag path", function()
  local world = grid.create(5, 5)
  local state = board.create()
  board.beginStroke(state, world, 2, 2, 1)
  board.continueStroke(state, world, 2, 4)
  assert.isTrue(grid.isAlive(world, 2, 2))
  assert.isTrue(grid.isAlive(world, 2, 3))
  assert.isTrue(grid.isAlive(world, 2, 4))
  board.endStroke(state)
end)
