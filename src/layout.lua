local M = {}

function M.computeGridSize(windowWidth, windowHeight, tileSize, statusBarHeight)
  local viewportHeight = windowHeight - statusBarHeight
  local cols = math.max(1, math.floor(windowWidth / tileSize))
  local rows = math.max(1, math.floor(viewportHeight / tileSize))
  return rows, cols
end

-- Letterbox centering for a fixed rows/cols/tileSize board in the viewport
-- above the status bar (same math renderer uses for offsets).
function M.computeBoardLayout(windowWidth, windowHeight, rows, cols, tileSize, statusBarHeight)
  local viewportHeight = windowHeight - statusBarHeight
  local boardWidth = cols * tileSize
  local boardHeight = rows * tileSize
  local offsetX = math.floor((windowWidth - boardWidth) / 2)
  local offsetY = math.floor((viewportHeight - boardHeight) / 2)

  return {
    offsetX = offsetX,
    offsetY = offsetY,
    boardWidth = boardWidth,
    boardHeight = boardHeight,
    tileSize = tileSize,
    rows = rows,
    cols = cols,
  }
end

return M
