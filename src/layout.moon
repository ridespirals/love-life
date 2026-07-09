computeGridSize = (windowWidth, windowHeight, tileSize, statusBarHeight) ->
  viewportHeight = windowHeight - statusBarHeight
  cols = math.max 1, math.floor(windowWidth / tileSize)
  rows = math.max 1, math.floor(viewportHeight / tileSize)
  rows, cols

return computeGridSize: computeGridSize
