stepAnimation = require "src.step_animation"
themes = require "src.themes"

easeIn = (t) -> t * t
lerp = (a, b, t) -> a + (b - a) * t

lerpColor = (color, target, amount) ->
  {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }

configPx = (config, key, default) ->
  value = config[key]
  return value if value ~= nil
  default

previewDotSize = (tileSize, config) ->
  scaled = tileSize * configPx(config, "previewDotScale", 0.15)
  math.max configPx(config, "previewDotMinPx", 4), scaled

tileDepth = (config, alive) ->
  if alive
    return configPx config, "tileDepthAlivePx", 3
  configPx config, "tileDepthDeadPx", 0

clampDepth = (depth, tileSize) ->
  return 0 if tileSize < 4
  math.min depth, math.floor(tileSize / 3)

getLayout = (config) ->
  windowWidth, windowHeight = love.graphics.getDimensions!
  boardWidth = config.cols * config.tileSize
  boardHeight = config.rows * config.tileSize
  viewportHeight = windowHeight - config.statusBarHeight
  offsetX = math.floor((windowWidth - boardWidth) / 2)
  offsetY = math.floor((viewportHeight - boardHeight) / 2)
  {
    offsetX: offsetX, offsetY: offsetY, boardWidth: boardWidth
    boardHeight: boardHeight, tileSize: config.tileSize
  }

setColor = (color) ->
  love.graphics.setColor color[1], color[2], color[3], 1

faceMetrics = (x, y, tileSize, depth) ->
  faceSize = tileSize - depth
  faceSize, x + faceSize / 2, y + faceSize / 2

drawExtrudedTile = (x, y, tileSize, theme, alive, depth) ->
  face = if alive then theme.alive else theme.dead
  depth = clampDepth depth, tileSize
  if depth <= 0
    setColor face
    love.graphics.rectangle "fill", x, y, tileSize, tileSize
    return
  faceSize = tileSize - depth
  shadow = themes.extrusionShadow theme, face, alive
  highlight = lerpColor face, { 1, 1, 1 }, if alive then 0.18 else 0.1
  setColor shadow
  love.graphics.rectangle "fill", x + depth, y + tileSize - depth, faceSize, depth
  love.graphics.rectangle "fill", x + tileSize - depth, y + depth, depth, faceSize
  setColor face
  love.graphics.rectangle "fill", x, y, faceSize, faceSize
  setColor highlight
  love.graphics.rectangle "fill", x, y, faceSize, 1
  love.graphics.rectangle "fill", x, y, 1, faceSize

drawCenteredSquare = (centerX, centerY, theme, alive, size) ->
  return if size <= 0
  setColor if alive then theme.alive else theme.dead
  half = size / 2
  love.graphics.rectangle "fill", centerX - half, centerY - half, size, size

drawSquareOnTile = (x, y, tileSize, theme, config, baseAlive, squareAlive, size) ->
  depth = tileDepth config, baseAlive
  drawExtrudedTile x, y, tileSize, theme, baseAlive, depth
  _, centerX, centerY = faceMetrics x, y, tileSize, clampDepth(depth, tileSize)
  drawCenteredSquare centerX, centerY, theme, squareAlive, size

drawBirthPreview = (x, y, tileSize, theme, config, previewSize, eased) ->
  size = previewSize * eased
  drawSquareOnTile x, y, tileSize, theme, config, false, true, size

drawBirthCommit = (x, y, tileSize, theme, config, previewSize, eased) ->
  depth = tileDepth config, true
  depth = clampDepth depth, tileSize
  faceSize = tileSize - depth
  size = lerp previewSize, faceSize, eased
  if size >= faceSize
    drawExtrudedTile x, y, tileSize, theme, true, depth
    return
  drawSquareOnTile x, y, tileSize, theme, config, false, true, size

drawDeathPreview = (x, y, tileSize, theme, config, previewSize, eased) ->
  size = previewSize * eased
  drawSquareOnTile x, y, tileSize, theme, config, true, false, size

drawDeathCommit = (x, y, tileSize, theme, config, previewSize, eased) ->
  aliveDepth = tileDepth config, true
  aliveDepth = clampDepth aliveDepth, tileSize
  faceSize = tileSize - aliveDepth
  _, centerX, centerY = faceMetrics x, y, tileSize, aliveDepth
  size = lerp previewSize, faceSize, eased
  if size >= faceSize
    drawExtrudedTile x, y, tileSize, theme, false, tileDepth(config, false)
    return
  drawExtrudedTile x, y, tileSize, theme, true, aliveDepth
  drawCenteredSquare centerX, centerY, theme, false, size

drawNextStatePreview = (x, y, tileSize, theme, config, alive, change, previewSize) ->
  return if change == "unchanged"
  depth = clampDepth tileDepth(config, alive), tileSize
  _, centerX, centerY = faceMetrics x, y, tileSize, depth
  previewAlive = change == "birth"
  drawCenteredSquare centerX, centerY, theme, previewAlive, previewSize

drawIdleCell = (x, y, tileSize, theme, config, alive, change, previewSize) ->
  drawExtrudedTile x, y, tileSize, theme, alive, tileDepth(config, alive)
  drawNextStatePreview x, y, tileSize, theme, config, alive, change, previewSize

drawCell = (world, theme, config, layout, row, col, animState) ->
  tileSize = layout.tileSize
  x = layout.offsetX + (col - 1) * tileSize
  y = layout.offsetY + (row - 1) * tileSize
  alive = world.current[row][col]
  change = stepAnimation.getCellChange world, row, col
  previewSize = previewDotSize tileSize, config
  if stepAnimation.isIdle animState
    drawIdleCell x, y, tileSize, theme, config, alive, change, previewSize
    return
  if change == "unchanged"
    drawExtrudedTile x, y, tileSize, theme, alive, tileDepth(config, alive)
    return
  phase, t = stepAnimation.getPhaseT animState
  eased = easeIn t
  if change == "birth"
    if phase == "preview"
      drawBirthPreview x, y, tileSize, theme, config, previewSize, eased
    else
      drawBirthCommit x, y, tileSize, theme, config, previewSize, eased
    return
  if phase == "preview"
    drawDeathPreview x, y, tileSize, theme, config, previewSize, eased
  else
    drawDeathCommit x, y, tileSize, theme, config, previewSize, eased

draw = (world, theme, config, animState) ->
  layout = getLayout config
  tileSize = layout.tileSize
  for row = 1, world.rows
    for col = 1, world.cols
      drawCell world, theme, config, layout, row, col, animState
  setColor theme.grid
  for col = 0, world.cols
    lineX = layout.offsetX + col * tileSize + 0.5
    love.graphics.line lineX, layout.offsetY + 0.5, lineX, layout.offsetY + layout.boardHeight + 0.5
  for row = 0, world.rows
    lineY = layout.offsetY + row * tileSize + 0.5
    love.graphics.line layout.offsetX + 0.5, lineY, layout.offsetX + layout.boardWidth + 0.5, lineY

return getLayout: getLayout, draw: draw
