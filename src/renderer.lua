local stepAnimation = require("src.step_animation")

local M = {}

local function easeIn(t)
  return t * t
end

local function lerp(from, to, t)
  return from + (to - from) * t
end

local function lerpColor(color, target, amount)
  return {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }
end

local function previewDotSize(tileSize, config)
  local scaled = tileSize * (config.previewDotScale or 0.05)
  return math.max(config.previewDotMinPx or 2, scaled)
end

local function tileDepth(config, alive)
  if alive then
    return config.tileDepthAlivePx or 2
  end
  return config.tileDepthDeadPx or 1
end

local function clampDepth(depth, tileSize)
  if tileSize < 4 then
    return 0
  end
  return math.min(depth, math.floor(tileSize / 3))
end

function M.getLayout(config)
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local boardWidth = config.cols * config.tileSize
  local boardHeight = config.rows * config.tileSize
  local viewportHeight = windowHeight - config.statusBarHeight
  local offsetX = math.floor((windowWidth - boardWidth) / 2)
  local offsetY = math.floor((viewportHeight - boardHeight) / 2)

  return {
    offsetX = offsetX,
    offsetY = offsetY,
    boardWidth = boardWidth,
    boardHeight = boardHeight,
    tileSize = config.tileSize,
  }
end

local function setColor(color)
  love.graphics.setColor(color[1], color[2], color[3], 1)
end

local function faceMetrics(x, y, tileSize, depth)
  local faceSize = tileSize - depth
  return faceSize, x + faceSize / 2, y + faceSize / 2
end

local function drawExtrudedTile(x, y, tileSize, theme, alive, depth)
  local face = alive and theme.alive or theme.dead
  depth = clampDepth(depth, tileSize)

  if depth <= 0 then
    setColor(face)
    love.graphics.rectangle("fill", x, y, tileSize, tileSize)
    return
  end

  local faceSize = tileSize - depth
  local shadow = lerpColor(face, { 0, 0, 0 }, alive and 0.35 or 0.2)
  local highlight = lerpColor(face, { 1, 1, 1 }, alive and 0.18 or 0.1)

  setColor(shadow)
  love.graphics.rectangle("fill", x + depth, y + tileSize - depth, faceSize, depth)
  love.graphics.rectangle("fill", x + tileSize - depth, y + depth, depth, faceSize)

  setColor(face)
  love.graphics.rectangle("fill", x, y, faceSize, faceSize)

  setColor(highlight)
  love.graphics.rectangle("fill", x, y, faceSize, 1)
  love.graphics.rectangle("fill", x, y, 1, faceSize)
end

local function drawCenteredSquare(centerX, centerY, theme, alive, size)
  if size <= 0 then
    return
  end
  setColor(alive and theme.alive or theme.dead)
  local half = size / 2
  love.graphics.rectangle("fill", centerX - half, centerY - half, size, size)
end

local function drawSquareOnTile(x, y, tileSize, theme, config, baseAlive, squareAlive, size)
  local depth = tileDepth(config, baseAlive)
  drawExtrudedTile(x, y, tileSize, theme, baseAlive, depth)
  local _, centerX, centerY = faceMetrics(x, y, tileSize, clampDepth(depth, tileSize))
  drawCenteredSquare(centerX, centerY, theme, squareAlive, size)
end

local function drawBirthPreview(x, y, tileSize, theme, config, previewSize, eased)
  local size = previewSize * eased
  drawSquareOnTile(x, y, tileSize, theme, config, false, true, size)
end

local function drawBirthCommit(x, y, tileSize, theme, config, previewSize, eased)
  local depth = tileDepth(config, true)
  depth = clampDepth(depth, tileSize)
  local faceSize = tileSize - depth
  local size = lerp(previewSize, faceSize, eased)

  if size >= faceSize then
    drawExtrudedTile(x, y, tileSize, theme, true, depth)
    return
  end

  drawSquareOnTile(x, y, tileSize, theme, config, false, true, size)
end

local function drawDeathPreview(x, y, tileSize, theme, config, previewSize, eased)
  local size = previewSize * eased
  drawSquareOnTile(x, y, tileSize, theme, config, true, false, size)
end

local function drawDeathCommit(x, y, tileSize, theme, config, previewSize, eased)
  local aliveDepth = tileDepth(config, true)
  aliveDepth = clampDepth(aliveDepth, tileSize)
  local faceSize = tileSize - aliveDepth
  local _, centerX, centerY = faceMetrics(x, y, tileSize, aliveDepth)
  local size = lerp(previewSize, faceSize, eased)

  if size >= faceSize then
    drawExtrudedTile(x, y, tileSize, theme, false, tileDepth(config, false))
    return
  end

  drawExtrudedTile(x, y, tileSize, theme, true, aliveDepth)
  drawCenteredSquare(centerX, centerY, theme, false, size)
end

local function drawNextStatePreview(x, y, tileSize, theme, config, alive, change, previewSize)
  if change == "unchanged" then
    return
  end

  local depth = clampDepth(tileDepth(config, alive), tileSize)
  local _, centerX, centerY = faceMetrics(x, y, tileSize, depth)
  local previewAlive = change == "birth"
  drawCenteredSquare(centerX, centerY, theme, previewAlive, previewSize)
end

local function drawIdleCell(x, y, tileSize, theme, config, alive, change, previewSize)
  drawExtrudedTile(x, y, tileSize, theme, alive, tileDepth(config, alive))
  drawNextStatePreview(x, y, tileSize, theme, config, alive, change, previewSize)
end
local function drawCell(world, theme, config, layout, row, col, animState)
  local tileSize = layout.tileSize
  local x = layout.offsetX + (col - 1) * tileSize
  local y = layout.offsetY + (row - 1) * tileSize
  local alive = world.current[row][col]
  local change = stepAnimation.getCellChange(world, row, col)
  local previewSize = previewDotSize(tileSize, config)

  if stepAnimation.isIdle(animState) then
    drawIdleCell(x, y, tileSize, theme, config, alive, change, previewSize)
    return
  end

  if change == "unchanged" then
    drawExtrudedTile(x, y, tileSize, theme, alive, tileDepth(config, alive))
    return
  end

  local phase, t = stepAnimation.getPhaseT(animState)
  local eased = easeIn(t)

  if change == "birth" then
    if phase == "preview" then
      drawBirthPreview(x, y, tileSize, theme, config, previewSize, eased)
    else
      drawBirthCommit(x, y, tileSize, theme, config, previewSize, eased)
    end
    return
  end

  if phase == "preview" then
    drawDeathPreview(x, y, tileSize, theme, config, previewSize, eased)
  else
    drawDeathCommit(x, y, tileSize, theme, config, previewSize, eased)
  end
end

function M.draw(world, theme, config, animState)
  local layout = M.getLayout(config)
  local tileSize = layout.tileSize

  for row = 1, world.rows do
    for col = 1, world.cols do
      drawCell(world, theme, config, layout, row, col, animState)
    end
  end

  setColor(theme.grid)
  for col = 0, world.cols do
    local x = layout.offsetX + col * tileSize + 0.5
    love.graphics.line(x, layout.offsetY + 0.5, x, layout.offsetY + layout.boardHeight + 0.5)
  end
  for row = 0, world.rows do
    local y = layout.offsetY + row * tileSize + 0.5
    love.graphics.line(layout.offsetX + 0.5, y, layout.offsetX + layout.boardWidth + 0.5, y)
  end
end

return M
