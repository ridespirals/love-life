setColor = (color, alpha) ->
  love.graphics.setColor color[1], color[2], color[3], alpha or 1

layoutRow = (x, y, items, gap) ->
  cursor = x
  for _, item in ipairs items
    item.x = cursor
    item.y = y
    cursor = cursor + item.w + gap
  items

layoutGrid = (x, y, items, gap, maxRowW) ->
  rowX = x
  rowY = y
  rowH = 0
  usedW = 0
  for _, item in ipairs items
    if rowX ~= x and rowX + item.w > x + maxRowW
      rowX = x
      rowY = rowY + rowH + gap
      rowH = 0
    item.x = rowX
    item.y = rowY
    rowH = math.max rowH, item.h
    rowX = rowX + item.w + gap
    usedW = math.max usedW, rowX - gap - x
  totalH = rowY - y + rowH
  items, usedW, totalH

drawButton = (button, theme, selected) ->
  if selected
    setColor theme.alive, 0.25
    love.graphics.rectangle "fill", button.x, button.y, button.w, button.h
  setColor theme.grid, 1
  love.graphics.rectangle "line", button.x + 0.5, button.y + 0.5, button.w, button.h
  setColor theme.alive, 1
  love.graphics.printf button.label, button.x, button.y + 4, button.w, "center"

hitButton = (button, x, y) ->
  x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h

drawField = (label, field, theme) ->
  labelY = field.y - 14
  if field.labelX
    fontH = 12
    fontH = love.graphics.getFont!\getHeight! if love and love.graphics and love.graphics.getFont
    labelY = field.y + math.floor((field.h - fontH) / 2)
  setColor theme.alive, 1
  love.graphics.print label, field.labelX or field.x, labelY
  if field.focused
    setColor theme.alive, 0.2
    love.graphics.rectangle "fill", field.x, field.y, field.w, field.h
  setColor theme.grid, 1
  love.graphics.rectangle "line", field.x + 0.5, field.y + 0.5, field.w, field.h
  setColor theme.alive, 1
  love.graphics.print field.value, field.x + 4, field.y + 3

drawColorSwatch = (swatch, color, theme) ->
  if color
    setColor color, 1
    love.graphics.rectangle "fill", swatch.x, swatch.y, swatch.w, swatch.h
  setColor theme.grid, 1
  love.graphics.rectangle "line", swatch.x + 0.5, swatch.y + 0.5, swatch.w, swatch.h

hitField = (field, x, y) ->
  x >= field.x and x <= field.x + field.w and y >= field.y and y <= field.y + field.h

return {
  layoutRow: layoutRow, layoutGrid: layoutGrid, drawButton: drawButton
  hitButton: hitButton, drawField: drawField, drawColorSwatch: drawColorSwatch
  hitField: hitField
}
