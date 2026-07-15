local grid = require("src.grid")

local M = {}

function M.create()
  return {
    stroke = nil,
  }
end

-- Inverse of renderer.getLayout tile math: window pixel -> 1-based cell.
function M.screenToCell(x, y, layout, world)
  local col = math.floor((x - layout.offsetX) / layout.tileSize) + 1
  local row = math.floor((y - layout.offsetY) / layout.tileSize) + 1

  if row < 1 or row > world.rows or col < 1 or col > world.cols then
    return nil
  end
  return row, col
end

function M.isDrawing(state)
  return state.stroke ~= nil
end

-- Left click toggles the pressed cell and the stroke keeps painting that
-- state; right click always paints dead (erase).
function M.beginStroke(state, world, row, col, button)
  local paint
  if button == 2 then
    paint = false
  else
    paint = not world.current[row][col]
  end

  state.stroke = {
    paint = paint,
    lastRow = row,
    lastCol = col,
  }
  grid.setAlive(world, row, col, paint)
  return true
end

-- Walk every cell between two stroke samples so fast drags leave no gaps.
local function paintLine(world, fromRow, fromCol, toRow, toCol, paint)
  local dRow = math.abs(toRow - fromRow)
  local dCol = math.abs(toCol - fromCol)
  local steps = math.max(dRow, dCol)
  if steps == 0 then
    return false
  end

  for i = 1, steps do
    local t = i / steps
    local row = math.floor(fromRow + (toRow - fromRow) * t + 0.5)
    local col = math.floor(fromCol + (toCol - fromCol) * t + 0.5)
    grid.setAlive(world, row, col, paint)
  end
  return true
end

function M.continueStroke(state, world, row, col)
  local stroke = state.stroke
  if not stroke then
    return false
  end
  if stroke.lastRow == row and stroke.lastCol == col then
    return false
  end

  local changed = paintLine(world, stroke.lastRow, stroke.lastCol, row, col, stroke.paint)
  stroke.lastRow = row
  stroke.lastCol = col
  return changed
end

function M.endStroke(state)
  state.stroke = nil
end

return M
