local stepAnimation = require("src.step_animation")

local M = {}

local function easeIn(t)
  return t * t
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

local function drawSolidTile(x, y, tileSize, theme, alive)
  setColor(alive and theme.alive or theme.dead)
  love.graphics.rectangle("fill", x, y, tileSize, tileSize)
end

local function drawCircle(centerX, centerY, theme, alive, radius)
  if radius <= 0 then
    return
  end
  setColor(alive and theme.alive or theme.dead)
  love.graphics.circle("fill", centerX, centerY, radius)
end

local function drawCircleOnTile(x, y, tileSize, centerX, centerY, theme, baseAlive, circleAlive, radius)
  drawSolidTile(x, y, tileSize, theme, baseAlive)
  drawCircle(centerX, centerY, theme, circleAlive, radius)
end

local function drawBirthMorph(x, y, tileSize, centerX, centerY, theme, fullRadius, eased)
  local radius = fullRadius * eased
  if radius >= fullRadius then
    drawSolidTile(x, y, tileSize, theme, true)
    return
  end
  drawCircleOnTile(x, y, tileSize, centerX, centerY, theme, false, true, radius)
end

local function drawDeathMorph(x, y, tileSize, centerX, centerY, theme, fullRadius, eased)
  local radius = fullRadius * (1 - eased)
  if radius <= 0 then
    drawSolidTile(x, y, tileSize, theme, false)
    return
  end
  if radius >= fullRadius then
    drawSolidTile(x, y, tileSize, theme, true)
    return
  end
  drawCircleOnTile(x, y, tileSize, centerX, centerY, theme, false, true, radius)
end

local function drawCell(world, theme, layout, row, col, animState)
  local tileSize = layout.tileSize
  local x = layout.offsetX + (col - 1) * tileSize
  local y = layout.offsetY + (row - 1) * tileSize
  local centerX = x + tileSize / 2
  local centerY = y + tileSize / 2
  local alive = world.current[row][col]
  local change = stepAnimation.getCellChange(world, row, col)
  local fullRadius = tileSize / 2

  if stepAnimation.isIdle(animState) or change == "unchanged" then
    drawSolidTile(x, y, tileSize, theme, alive)
    return
  end

  local eased = easeIn(stepAnimation.getMorphT(animState))

  if change == "birth" then
    drawBirthMorph(x, y, tileSize, centerX, centerY, theme, fullRadius, eased)
  else
    drawDeathMorph(x, y, tileSize, centerX, centerY, theme, fullRadius, eased)
  end
end

function M.draw(world, theme, config, animState)
  local layout = M.getLayout(config)
  local tileSize = layout.tileSize

  for row = 1, world.rows do
    for col = 1, world.cols do
      drawCell(world, theme, layout, row, col, animState)
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
