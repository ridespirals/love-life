local text_field = require("src.ui.text_field")

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

function M.drawButton(button, theme, selected, disabled, hovered)
  local alpha = disabled and 0.35 or 1
  if selected and not disabled then
    setColor(theme.alive, 0.25)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
  elseif hovered and not disabled then
    setColor(theme.alive, 0.14)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
  end
  setColor(theme.grid, alpha)
  love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.w, button.h)
  setColor(theme.alive, alpha)
  love.graphics.printf(button.label, button.x, button.y + 4, button.w, "center")
end

function M.hitButton(button, x, y)
  return x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h
end

function M.isHovered(button, session)
  if not session or session.pointerX == nil or session.pointerY == nil then
    return false
  end
  return M.hitButton(button, session.pointerX, session.pointerY)
end

-- Shared hover wash for status-bar chips, toolbar buttons, etc.
function M.drawHoverWash(rect, theme, amount)
  if not rect then
    return
  end
  setColor(theme.alive, amount or 0.14)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
end

function M.drawField(label, field, theme, disabled, session)
  local alpha = disabled and 0.35 or 1
  local labelY = field.y - 14
  if field.labelX then
    local fontH = 12
    if love and love.graphics and love.graphics.getFont then
      fontH = love.graphics.getFont():getHeight()
    end
    labelY = field.y + math.floor((field.h - fontH) / 2)
  end
  setColor(theme.alive, alpha)
  love.graphics.print(label, field.labelX or field.x, labelY)
  if field.focused and not disabled then
    setColor(theme.alive, 0.2)
    love.graphics.rectangle("fill", field.x, field.y, field.w, field.h)
  end
  setColor(theme.grid, alpha)
  love.graphics.rectangle("line", field.x + 0.5, field.y + 0.5, field.w, field.h)
  text_field.drawContents(field, field.value, theme, session, disabled)
end

function M.focusField(session, value, field, mouseX)
  local extend = false
  if love and love.keyboard then
    extend = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
  end
  if extend and session.fieldSelAnchor ~= nil then
    text_field.pointerDown(session, value, field, mouseX, true)
  else
    text_field.onFocus(session, value)
    text_field.pointerDown(session, value, field, mouseX, false)
  end
end

function M.drawColorSwatch(swatch, color, theme)
  if color then
    setColor(color, 1)
    love.graphics.rectangle("fill", swatch.x, swatch.y, swatch.w, swatch.h)
  end
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", swatch.x + 0.5, swatch.y + 0.5, swatch.w, swatch.h)
end

function M.hitField(field, x, y)
  return x >= field.x and x <= field.x + field.w and y >= field.y and y <= field.y + field.h
end

return M
