CHIP_GAP = 16
CHIP_PAD_X = 4
CHIP_PAD_Y = 2

buttonSpecs = {
  { id: "settings", label: "Settings" },
  { id: "play", label: "Play" },
  { id: "pause", label: "Pause" },
  { id: "step", label: "Step" },
  { id: "restart", label: "Restart" },
}

setColor = (color, alpha) ->
  love.graphics.setColor color[1], color[2], color[3], alpha or 1

contains = (rect, x, y) ->
  x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h

estimateTextWidth = (text) ->
  if love.graphics.getFont
    return love.graphics.getFont!\getWidth text
  #text * 7

getChips = (world, theme, config, activeRule, generation, patternId) ->
  width, height = love.graphics.getDimensions!
  barTop = height - config.statusBarHeight
  textY = barTop + math.floor((config.statusBarHeight - 12) / 2)
  y = textY - CHIP_PAD_Y
  h = 12 + CHIP_PAD_Y * 2
  specs = {
    { id: "rule", paneId: "rule", label: "Rule: #{activeRule.rulestring}" },
    { id: "theme", paneId: "theme", label: "Theme: #{theme.name}" },
    { id: "pattern", paneId: "pattern", label: "Pattern: #{patternId}" },
    { id: "size", paneId: "settings", label: "Size: #{world.rows}x#{world.cols}" },
    { id: "gen", paneId: nil, label: "Gen: #{generation}" },
  }
  chips = {}
  x = 10
  for _, spec in ipairs specs
    w = estimateTextWidth(spec.label) + CHIP_PAD_X * 2
    table.insert chips, {
      id: spec.id, paneId: spec.paneId, label: spec.label
      clickable: spec.paneId ~= nil, x: x, y: y, w: w, h: h
    }
    x = x + w + CHIP_GAP
  chips

getButtons = (config, fastMode) ->
  width, height = love.graphics.getDimensions!
  barTop = height - config.statusBarHeight
  buttonHeight = config.statusBarHeight - 8
  buttonWidth = 60
  gap = 8
  x = width - 10 - (#buttonSpecs * buttonWidth) - ((#buttonSpecs - 1) * gap)
  y = barTop + 4
  buttons = {}
  for _, spec in ipairs buttonSpecs
    label = spec.label
    label = "Play +" if fastMode and spec.id == "play"
    table.insert buttons, { id: spec.id, label: label, x: x, y: y, w: buttonWidth, h: buttonHeight }
    x = x + buttonWidth + gap
  buttons

getButton = (config, fastMode, id) ->
  for _, button in ipairs getButtons(config, fastMode)
    return button if button.id == id

matchesAnchor = (anchor, rect) ->
  return false unless anchor and rect
  anchor.x == rect.x and anchor.y == rect.y and anchor.w == rect.w and anchor.h == rect.h

drawOpenerLabel = (world, theme, config, activeRule, generation, patternId, fastMode, anchor) ->
  return unless anchor
  for _, chip in ipairs getChips(world, theme, config, activeRule, generation, patternId)
    if matchesAnchor anchor, chip
      setColor theme.alive, 1
      love.graphics.print chip.label, chip.x + CHIP_PAD_X, chip.y + CHIP_PAD_Y
      return
  for _, button in ipairs getButtons(config, fastMode)
    if matchesAnchor anchor, button
      setColor theme.alive, 1
      love.graphics.printf button.label, button.x, button.y + 6, button.w, "center"
      return

draw = (world, theme, config, activeRule, generation, patternId, fastMode, paneState) ->
  width, height = love.graphics.getDimensions!
  barTop = height - config.statusBarHeight
  setColor theme.dead, 0.95
  love.graphics.rectangle "fill", 0, barTop, width, config.statusBarHeight
  setColor theme.grid, 1
  love.graphics.line 0, barTop + 0.5, width, barTop + 0.5
  activeAnchor = paneState and paneState.anchor
  chips = getChips world, theme, config, activeRule, generation, patternId
  for _, chip in ipairs chips
    if chip.clickable and not matchesAnchor(activeAnchor, chip)
      setColor theme.grid, 0.35
      love.graphics.rectangle "fill", chip.x, chip.y, chip.w, chip.h
      setColor theme.grid, 0.8
      love.graphics.rectangle "line", chip.x + 0.5, chip.y + 0.5, chip.w, chip.h
    unless matchesAnchor(activeAnchor, chip)
      setColor theme.alive, 1
      love.graphics.print chip.label, chip.x + CHIP_PAD_X, chip.y + CHIP_PAD_Y
  buttons = getButtons config, fastMode
  for _, button in ipairs buttons
    unless matchesAnchor(activeAnchor, button)
      setColor theme.grid, 1
      love.graphics.rectangle "line", button.x + 0.5, button.y + 0.5, button.w, button.h
      setColor theme.alive, 1
      love.graphics.printf button.label, button.x, button.y + 6, button.w, "center"

hitTestChip = (world, theme, config, activeRule, generation, patternId, x, y) ->
  for _, chip in ipairs getChips(world, theme, config, activeRule, generation, patternId)
    return chip.paneId, chip if chip.clickable and contains(chip, x, y)

hitTestButton = (config, x, y, fastMode) ->
  for _, button in ipairs getButtons(config, fastMode)
    return button.id if contains(button, x, y)

return {
  getChips: getChips, getButtons: getButtons, getButton: getButton
  drawOpenerLabel: drawOpenerLabel, draw: draw
  hitTestChip: hitTestChip, hitTestButton: hitTestButton
}
