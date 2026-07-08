local M = {}

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
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

local function previewDotRadius(config)
  local rawRadius = config.tileSize * config.previewDotScale
  return clamp(rawRadius, config.previewDotMinRadiusPx, config.previewDotMaxRadiusPx)
end

local function setColor(color)
  love.graphics.setColor(color[1], color[2], color[3], 1)
end

function M.draw(world, theme, config)
  local layout = M.getLayout(config)
  local tileSize = layout.tileSize
  local dotRadius = previewDotRadius(config)

  for row = 1, world.rows do
    for col = 1, world.cols do
      local alive = world.current[row][col]
      local x = layout.offsetX + (col - 1) * tileSize
      local y = layout.offsetY + (row - 1) * tileSize

      if alive then
        setColor(theme.alive)
      else
        setColor(theme.dead)
      end
      love.graphics.rectangle("fill", x, y, tileSize, tileSize)

      local willBeAlive = world.next[row][col]
      if alive ~= willBeAlive then
        local centerX = x + tileSize / 2
        local centerY = y + tileSize / 2
        if willBeAlive then
          setColor(theme.alive)
        else
          setColor(theme.dead)
        end
        love.graphics.circle("fill", centerX, centerY, dotRadius)
      end
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
