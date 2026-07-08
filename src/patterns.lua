local grid = require("src.grid")

local M = {}

local defaultPattern = "glider"

local function wrap(index, size)
  return ((index - 1) % size) + 1
end

local function getBounds(cells)
  local minCol, maxCol = math.huge, -math.huge
  local minRow, maxRow = math.huge, -math.huge

  for _, cell in ipairs(cells) do
    local col = cell[1]
    local row = cell[2]
    minCol = math.min(minCol, col)
    maxCol = math.max(maxCol, col)
    minRow = math.min(minRow, row)
    maxRow = math.max(maxRow, row)
  end

  return minCol, maxCol, minRow, maxRow
end

function M.get(id)
  local moduleId = id or defaultPattern
  local ok, pattern = pcall(require, "patterns." .. moduleId)
  if ok then
    return pattern
  end

  return require("patterns." .. defaultPattern)
end

function M.list()
  return {
    "glider",
    "blinker",
    "beacon",
  }
end

function M.apply(world, patternId)
  local pattern = M.get(patternId)
  local minCol, maxCol, minRow, maxRow = getBounds(pattern.cells)
  local width = maxCol - minCol + 1
  local height = maxRow - minRow + 1

  local originCol = math.floor((world.cols - width) / 2) + 1 - minCol
  local originRow = math.floor((world.rows - height) / 2) + 1 - minRow

  grid.clear(world)

  for _, cell in ipairs(pattern.cells) do
    local col = wrap(originCol + cell[1], world.cols)
    local row = wrap(originRow + cell[2], world.rows)
    grid.setAlive(world, row, col, true)
  end
end

return M
