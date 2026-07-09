local M = {}

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

function M.layoutRow(x, y, items, gap)
  local cursor = x
  for _, item in ipairs(items) do
    item.x = cursor
    item.y = y
    cursor = cursor + item.w + gap
  end
  return items
end

-- Wraps items into rows capped at maxRowW so wide catalogs (e.g. 21 themes)
-- don't produce a pane wider than the screen. Returns the widest row width
-- and total stacked height so callers can size the pane consistently.
function M.layoutGrid(x, y, items, gap, maxRowW)
  local rowX = x
  local rowY = y
  local rowH = 0
  local usedW = 0

  for _, item in ipairs(items) do
    if rowX ~= x and rowX + item.w > x + maxRowW then
      rowX = x
      rowY = rowY + rowH + gap
      rowH = 0
    end
    item.x = rowX
    item.y = rowY
    rowH = math.max(rowH, item.h)
    rowX = rowX + item.w + gap
    usedW = math.max(usedW, rowX - gap - x)
  end

  local totalH = rowY - y + rowH
  return items, usedW, totalH
end

function M.drawButton(button, theme, selected)
  if selected then
    setColor(theme.alive, 0.25)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
  end
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.w, button.h)
  setColor(theme.alive, 1)
  love.graphics.printf(button.label, button.x, button.y + 4, button.w, "center")
end

function M.hitButton(button, x, y)
  return x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h
end

function M.drawField(label, field, theme)
  setColor(theme.alive, 1)
  love.graphics.print(label, field.labelX or field.x, field.y - 14)
  if field.focused then
    setColor(theme.alive, 0.2)
    love.graphics.rectangle("fill", field.x, field.y, field.w, field.h)
  end
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", field.x + 0.5, field.y + 0.5, field.w, field.h)
  setColor(theme.alive, 1)
  love.graphics.print(field.value, field.x + 4, field.y + 3)
end

function M.hitField(field, x, y)
  return x >= field.x and x <= field.x + field.w and y >= field.y and y <= field.y + field.h
end

return M
