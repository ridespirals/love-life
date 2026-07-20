local stepAnimation = require("src.step_animation")
local themes = require("src.themes")
local layout = require("src.layout")
local camera = require("src.camera")

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

local function configPx(config, key, default)
  local value = config[key]
  if value ~= nil then
    return value
  end
  return default
end

local function previewDotSize(tileSize, config)
  local scaled = tileSize * configPx(config, "previewDotScale", 0.15)
  return math.max(configPx(config, "previewDotMinPx", 4), scaled)
end

local function tileDepth(config, alive)
  if alive then
    return configPx(config, "tileDepthAlivePx", 3)
  end
  return configPx(config, "tileDepthDeadPx", 0)
end

local function clampDepth(depth, tileSize)
  if tileSize < 4 then
    return 0
  end
  return math.min(depth, math.floor(tileSize / 3))
end

function M.getLayout(config, cam)
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local viewH = windowHeight - config.statusBarHeight
  if cam then
    return camera.computeLayout(cam, config, windowWidth, viewH)
  end
  return layout.computeBoardLayout(
    windowWidth,
    windowHeight,
    config.rows,
    config.cols,
    config.baseVisualTile or config.tileSize,
    config.statusBarHeight
  )
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
  local shadow = themes.extrusionShadow(theme, face, alive)
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

local function drawIdleCell(x, y, tileSize, theme, config, alive, change, previewSize, lod)
  if lod then
    setColor(alive and theme.alive or theme.dead)
    love.graphics.rectangle("fill", x, y, tileSize, tileSize)
    return
  end
  drawExtrudedTile(x, y, tileSize, theme, alive, tileDepth(config, alive))
  drawNextStatePreview(x, y, tileSize, theme, config, alive, change, previewSize)
end

function M.drawHover(config, cam, row, col, theme)
  if not row or not col or not theme then
    return
  end
  local boardLayout = M.getLayout(config, cam)
  local tileSize = boardLayout.tileSize
  local x = boardLayout.offsetX + (col - 1) * tileSize
  local y = boardLayout.offsetY + (row - 1) * tileSize
  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 0.35)
  love.graphics.rectangle("fill", x, y, tileSize, tileSize)
  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 0.9)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, tileSize, tileSize)
end

local function useLod(tileSize, config)
  return tileSize < (config.stepAnimMinTileSize or 6)
end

local function drawCell(world, theme, config, layout, row, col, animState, lod)
  local tileSize = layout.tileSize
  local x = layout.offsetX + (col - 1) * tileSize
  local y = layout.offsetY + (row - 1) * tileSize
  local alive = world.current[row][col]
  local change = stepAnimation.getCellChange(world, row, col)
  local previewSize = previewDotSize(tileSize, config)

  if lod or stepAnimation.isIdle(animState) or not stepAnimation.effectiveEnabled(config, tileSize) then
    drawIdleCell(x, y, tileSize, theme, config, alive, change, previewSize, lod)
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

function M.draw(world, theme, config, animState, cam)
  local boardLayout = M.getLayout(config, cam)
  local tileSize = boardLayout.tileSize
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local viewH = windowHeight - config.statusBarHeight
  local lod = useLod(tileSize, config)
  local rowStart, rowEnd, colStart, colEnd = camera.visibleCellRange(boardLayout, windowWidth, viewH)

  for row = rowStart, rowEnd do
    for col = colStart, colEnd do
      drawCell(world, theme, config, boardLayout, row, col, animState, lod)
    end
  end

  if lod or tileSize < 3 then
    return
  end

  setColor(theme.grid)
  for col = colStart - 1, colEnd do
    local x = boardLayout.offsetX + col * tileSize + 0.5
    local y0 = boardLayout.offsetY + (rowStart - 1) * tileSize + 0.5
    local y1 = boardLayout.offsetY + rowEnd * tileSize + 0.5
    love.graphics.line(x, y0, x, y1)
  end
  for row = rowStart - 1, rowEnd do
    local y = boardLayout.offsetY + row * tileSize + 0.5
    local x0 = boardLayout.offsetX + (colStart - 1) * tileSize + 0.5
    local x1 = boardLayout.offsetX + colEnd * tileSize + 0.5
    love.graphics.line(x0, y, x1, y)
  end
end

return M
