local M = {}

function M.computeGridSize(windowWidth, windowHeight, tileSize, statusBarHeight)
  local viewportHeight = windowHeight - statusBarHeight
  local cols = math.max(1, math.floor(windowWidth / tileSize))
  local rows = math.max(1, math.floor(viewportHeight / tileSize))
  return rows, cols
end

return M
