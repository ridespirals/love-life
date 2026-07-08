local M = {}

local function wrap(index, size)
  return ((index - 1) % size) + 1
end

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
        local neighborRow = wrap(row + dRow, world.rows)
        local neighborCol = wrap(col + dCol, world.cols)
        if world.current[neighborRow][neighborCol] then
          count = count + 1
        end
      end
    end
  end

  return count
end

function M.computeNext(world)
  for row = 1, world.rows do
    for col = 1, world.cols do
      local alive = world.current[row][col]
      local neighbors = M.countNeighbors(world, row, col)

      if alive then
        world.next[row][col] = neighbors == 2 or neighbors == 3
      else
        world.next[row][col] = neighbors == 3
      end
    end
  end
end

function M.step(world)
  world.current, world.next = world.next, world.current
  M.computeNext(world)
end

function M.isAlive(world, row, col)
  return world.current[row][col]
end

-- Glider offsets from placement origin (col, row), 0-based deltas.
local gliderCells = {
  { 1, 0 },
  { 2, 1 },
  { 0, 2 },
  { 1, 2 },
  { 2, 2 },
}

function M.seedGlider(world)
  M.clear(world)

  local originCol = math.floor((world.cols - 3) / 2) + 1
  local originRow = math.floor((world.rows - 3) / 2) + 1

  for _, cell in ipairs(gliderCells) do
    local col = wrap(originCol + cell[1], world.cols)
    local row = wrap(originRow + cell[2], world.rows)
    world.current[row][col] = true
  end
end

return M
