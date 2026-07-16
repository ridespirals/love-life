local M = {}

local CHIP_GAP = 16
local CHIP_PAD_X = 4
local CHIP_PAD_Y = 2
local widgets = require("src.ui.pane_widgets")

local buttonSpecs = {
  { id = "settings", label = "Settings" },
  { id = "play", label = "Play" },
  { id = "pause", label = "Pause" },
  { id = "step", label = "Step" },
  { id = "restart", label = "Restart" },
}

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function contains(rect, x, y)
  return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function estimateTextWidth(text)
  if love.graphics.getFont then
    return love.graphics.getFont():getWidth(text)
  end
  return #text * 7
end

function M.getChips(world, theme, config, activeRule, generation, patternId)
  local width, height = love.graphics.getDimensions()
  local barTop = height - config.statusBarHeight
  local textY = barTop + math.floor((config.statusBarHeight - 12) / 2)
  local y = textY - CHIP_PAD_Y
  local h = 12 + CHIP_PAD_Y * 2

  local specs = {
    { id = "rule", paneId = "rule", label = string.format("Rule: %s", activeRule.rulestring) },
    { id = "theme", paneId = "theme", label = string.format("Theme: %s", theme.name) },
    { id = "pattern", paneId = "pattern", label = string.format("Pattern: %s", patternId) },
    { id = "size", paneId = "settings", label = string.format("Size: %dx%d", world.rows, world.cols) },
    { id = "gen", paneId = nil, label = string.format("Gen: %d", generation) },
  }

  local chips = {}
  local x = 10
  for _, spec in ipairs(specs) do
    local w = estimateTextWidth(spec.label) + CHIP_PAD_X * 2
    chips[#chips + 1] = {
      id = spec.id,
      paneId = spec.paneId,
      label = spec.label,
      clickable = spec.paneId ~= nil,
      x = x,
      y = y,
      w = w,
      h = h,
    }
    x = x + w + CHIP_GAP
  end

  return chips
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

function M.getButton(config, fastMode, id)
  for _, button in ipairs(M.getButtons(config, fastMode)) do
    if button.id == id then
      return button
    end
  end
end

local function matchesAnchor(anchor, rect)
  if not anchor or not rect then
    return false
  end
  return anchor.x == rect.x
    and anchor.y == rect.y
    and anchor.w == rect.w
    and anchor.h == rect.h
end

function M.drawOpenerLabel(world, theme, config, activeRule, generation, patternId, fastMode, anchor)
  if not anchor then
    return
  end

  for _, chip in ipairs(M.getChips(world, theme, config, activeRule, generation, patternId)) do
    if matchesAnchor(anchor, chip) then
      setColor(theme.alive, 1)
      love.graphics.print(chip.label, chip.x + CHIP_PAD_X, chip.y + CHIP_PAD_Y)
      return
    end
  end

  for _, button in ipairs(M.getButtons(config, fastMode)) do
    if matchesAnchor(anchor, button) then
      setColor(theme.alive, 1)
      love.graphics.printf(button.label, button.x, button.y + 6, button.w, "center")
      return
    end
  end
end

function M.draw(world, theme, config, activeRule, generation, patternId, fastMode, paneState, pointerX, pointerY)
  local width, height = love.graphics.getDimensions()
  local barTop = height - config.statusBarHeight

  setColor(theme.dead, 0.95)
  love.graphics.rectangle("fill", 0, barTop, width, config.statusBarHeight)

  setColor(theme.grid, 1)
  love.graphics.line(0, barTop + 0.5, width, barTop + 0.5)

  local activeAnchor = paneState and paneState.anchor or nil
  local hasPointer = pointerX ~= nil and pointerY ~= nil

  local chips = M.getChips(world, theme, config, activeRule, generation, patternId)
  for _, chip in ipairs(chips) do
    if chip.clickable and not matchesAnchor(activeAnchor, chip) then
      local hovered = hasPointer and contains(chip, pointerX, pointerY)
      if hovered then
        widgets.drawHoverWash(chip, theme, 0.18)
      else
        setColor(theme.grid, 0.35)
        love.graphics.rectangle("fill", chip.x, chip.y, chip.w, chip.h)
      end
      setColor(theme.grid, 0.8)
      love.graphics.rectangle("line", chip.x + 0.5, chip.y + 0.5, chip.w, chip.h)
    end
    if not matchesAnchor(activeAnchor, chip) then
      setColor(theme.alive, 1)
      love.graphics.print(chip.label, chip.x + CHIP_PAD_X, chip.y + CHIP_PAD_Y)
    end
  end

  local buttons = M.getButtons(config, fastMode)
  for _, button in ipairs(buttons) do
    if not matchesAnchor(activeAnchor, button) then
      local hovered = hasPointer and contains(button, pointerX, pointerY)
      if hovered then
        widgets.drawHoverWash(button, theme, 0.14)
      end
      setColor(theme.grid, 1)
      love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.w, button.h)
      setColor(theme.alive, 1)
      love.graphics.printf(button.label, button.x, button.y + 6, button.w, "center")
    end
  end
end

function M.hitTestChip(world, theme, config, activeRule, generation, patternId, x, y)
  for _, chip in ipairs(M.getChips(world, theme, config, activeRule, generation, patternId)) do
    if chip.clickable and contains(chip, x, y) then
      return chip.paneId, chip
    end
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
