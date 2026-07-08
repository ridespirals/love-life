local M = {}

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

function M.draw(world, theme, config, activeRules)
  local width, height = love.graphics.getDimensions()
  local barTop = height - config.statusBarHeight

  setColor(theme.dead, 0.95)
  love.graphics.rectangle("fill", 0, barTop, width, config.statusBarHeight)

  setColor(theme.grid, 1)
  love.graphics.line(0, barTop + 0.5, width, barTop + 0.5)

  local text = string.format(
    "Rule: %s   Size: %dx%d   Theme: %s   Step: %.2fs",
    activeRules.rulestring,
    world.rows,
    world.cols,
    theme.name,
    config.stepInterval
  )

  setColor(theme.alive, 1)
  love.graphics.print(text, 10, barTop + math.floor((config.statusBarHeight - 12) / 2))
end

return M
