local util = require("src.util")

local M = {}

function M.create(rows, cols)
  local current = {}
  for row = 1, rows do
    current[row] = {}
    for col = 1, cols do
      current[row][col] = false
    end
  end

  local nextCells = {}
  for row = 1, rows do
    nextCells[row] = {}
    for col = 1, cols do
      nextCells[row][col] = false
    end
  end

  return {
    rows = rows,
    cols = cols,
    current = current,
    next = nextCells,
  }
end

function M.clear(world)
  for row = 1, world.rows do
    for col = 1, world.cols do
      world.current[row][col] = false
    end
  end
end

function M.setAlive(world, row, col, alive)
  world.current[row][col] = alive
end

function M.countNeighbors(world, row, col)
  local count = 0

  for dRow = -1, 1 do
    for dCol = -1, 1 do
      if dRow ~= 0 or dCol ~= 0 then
        local neighborRow = util.wrap(row + dRow, world.rows)
        local neighborCol = util.wrap(col + dCol, world.cols)
        if world.current[neighborRow][neighborCol] then
          count = count + 1
        end
      end
    end
  end

  return count
end

function M.computeNext(world, rules)
  for row = 1, world.rows do
    for col = 1, world.cols do
      local alive = world.current[row][col]
      local neighbors = M.countNeighbors(world, row, col)

      if alive then
        world.next[row][col] = rules.survival[neighbors] == true
      else
        world.next[row][col] = rules.birth[neighbors] == true
      end
    end
  end
end

function M.step(world, rules)
  world.current, world.next = world.next, world.current
  M.computeNext(world, rules)
end

function M.isAlive(world, row, col)
  return world.current[row][col]
end

-- Rebuild buffers at new dimensions, centering the previous board in the
-- new grid so an in-progress simulation survives grid setting changes.
function M.resize(world, newRows, newCols)
  local newWorld = M.create(newRows, newCols)
  local rowOffset = math.floor((newRows - world.rows) / 2)
  local colOffset = math.floor((newCols - world.cols) / 2)

  for row = 1, world.rows do
    for col = 1, world.cols do
      local destRow = row + rowOffset
      local destCol = col + colOffset
      if destRow >= 1 and destRow <= newRows and destCol >= 1 and destCol <= newCols then
        newWorld.current[destRow][destCol] = world.current[row][col]
      end
    end
  end

  return newWorld
end

return M
