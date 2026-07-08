local M = {}

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local buttonSpecs = {
  { id = "play", label = "Play" },
  { id = "pause", label = "Pause" },
  { id = "step", label = "Step" },
  { id = "restart", label = "Restart" },
}

local function contains(rect, x, y)
  return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function M.getButtons(config, fastMode)
  local width, height = love.graphics.getDimensions()
  local barTop = height - config.statusBarHeight
  local buttonHeight = config.statusBarHeight - 8
  local buttonWidth = 60
  local gap = 8
  local x = width - 10 - (#buttonSpecs * buttonWidth) - ((#buttonSpecs - 1) * gap)
  local y = barTop + 4

  local buttons = {}
  for _, spec in ipairs(buttonSpecs) do
    local label = spec.label
    if fastMode and spec.id == "play" then
      label = "Play +"
    end

    buttons[#buttons + 1] = {
      id = spec.id,
      label = label,
      x = x,
      y = y,
      w = buttonWidth,
      h = buttonHeight,
    }
    x = x + buttonWidth + gap
  end

  return buttons
end

function M.draw(world, theme, config, activeRule, generation, fastMode)
  local width, height = love.graphics.getDimensions()
  local barTop = height - config.statusBarHeight

  setColor(theme.dead, 0.95)
  love.graphics.rectangle("fill", 0, barTop, width, config.statusBarHeight)

  setColor(theme.grid, 1)
  love.graphics.line(0, barTop + 0.5, width, barTop + 0.5)

  local text = string.format(
    "Rule: %s   Size: %dx%d   Theme: %s   Gen: %d",
    activeRule.rulestring,
    world.rows,
    world.cols,
    theme.name,
    generation
  )

  setColor(theme.alive, 1)
  love.graphics.print(text, 10, barTop + math.floor((config.statusBarHeight - 12) / 2))

  local buttons = M.getButtons(config, fastMode)
  for _, button in ipairs(buttons) do
    setColor(theme.grid, 1)
    love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.w, button.h)
    setColor(theme.alive, 1)
    love.graphics.printf(button.label, button.x, button.y + 6, button.w, "center")
  end
end

function M.hitTestButton(config, x, y, fastMode)
  for _, button in ipairs(M.getButtons(config, fastMode)) do
    if contains(button, x, y) then
      return button.id
    end
  end
end

return M
