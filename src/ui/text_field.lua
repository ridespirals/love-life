local M = {}

local TEXT_PAD_X = 4
local TEXT_PAD_Y = 3

local function clamp(n, min, max)
  if n < min then
    return min
  end
  if n > max then
    return max
  end
  return n
end

function M.clearSelection(session)
  session.fieldSelStart = nil
  session.fieldSelEnd = nil
end

function M.onFocus(session, value, opts)
  opts = opts or {}
  session.fieldCaret = opts.caret
  if session.fieldCaret == nil then
    session.fieldCaret = #(value or "")
  end
  session.fieldSelAnchor = session.fieldCaret
  M.clearSelection(session)
  session.fieldDragging = false
end

function M.selectionRange(session)
  if session.fieldSelStart == nil or session.fieldSelEnd == nil then
    return nil
  end
  local start = session.fieldSelStart
  local stop = session.fieldSelEnd
  if start == stop then
    return nil
  end
  if start > stop then
    return stop, start
  end
  return start, stop
end

function M.hasSelection(session)
  return M.selectionRange(session) ~= nil
end

function M.deleteSelection(value, session)
  local start, stop = M.selectionRange(session)
  if not start then
    return value, false
  end
  value = string.sub(value, 1, start) .. string.sub(value, stop + 1)
  session.fieldCaret = start
  M.clearSelection(session)
  return value, true
end

function M.insert(session, value, text)
  value = value or ""
  local start, stop = M.selectionRange(session)
  if start then
    value = string.sub(value, 1, start) .. text .. string.sub(value, stop + 1)
    session.fieldCaret = start + #text
    M.clearSelection(session)
    return value
  end

  local caret = session.fieldCaret or #value
  value = string.sub(value, 1, caret) .. text .. string.sub(value, caret + 1)
  session.fieldCaret = caret + #text
  return value
end

function M.indexAtX(measureWidth, value, textX, mouseX)
  value = value or ""
  local relative = mouseX - textX - TEXT_PAD_X
  if relative <= 0 then
    return 0
  end

  local lastWidth = 0
  for i = 1, #value do
    local width = measureWidth(string.sub(value, 1, i))
    if width >= relative then
      if (relative - lastWidth) < (width - relative) then
        return i - 1
      end
      return i
    end
    lastWidth = width
  end
  return #value
end

function M.pointerDown(session, value, field, mouseX, extendSelection)
  if not (love and love.graphics and love.graphics.getFont) then
    return
  end
  local measureWidth = function(text)
    return love.graphics.getFont():getWidth(text)
  end
  local index = M.indexAtX(measureWidth, value, field.x, mouseX)
  session.fieldCaret = index
  if extendSelection then
    session.fieldSelStart = session.fieldSelAnchor
    session.fieldSelEnd = index
  else
    session.fieldSelAnchor = index
    M.clearSelection(session)
  end
  session.fieldDragging = true
end

function M.pointerDrag(session, value, field, mouseX)
  if not session.fieldDragging then
    return
  end
  if not (love and love.graphics and love.graphics.getFont) then
    return
  end
  local measureWidth = function(text)
    return love.graphics.getFont():getWidth(text)
  end
  local index = M.indexAtX(measureWidth, value, field.x, mouseX)
  session.fieldCaret = index
  session.fieldSelStart = session.fieldSelAnchor
  session.fieldSelEnd = index
end

function M.pointerUp(session)
  session.fieldDragging = false
end

local function isModDown()
  if not (love and love.keyboard) then
    return false
  end
  return love.keyboard.isDown("lctrl")
    or love.keyboard.isDown("rctrl")
    or love.keyboard.isDown("lgui")
    or love.keyboard.isDown("rgui")
end

local function isShiftDown()
  if not (love and love.keyboard) then
    return false
  end
  return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function M.selectAll(session, value)
  value = value or ""
  session.fieldSelStart = 0
  session.fieldSelEnd = #value
  session.fieldCaret = #value
  session.fieldSelAnchor = 0
end

local function moveCaret(session, value, nextCaret, keepSelection)
  session.fieldCaret = clamp(nextCaret, 0, #value)
  if keepSelection then
    session.fieldSelStart = session.fieldSelAnchor
    session.fieldSelEnd = session.fieldCaret
  else
    session.fieldSelAnchor = session.fieldCaret
    M.clearSelection(session)
  end
end

function M.keypressed(session, value, key)
  value = value or ""

  if key == "a" and isModDown() then
    M.selectAll(session, value)
    return value, true
  end

  if key == "backspace" then
    local start, stop = M.selectionRange(session)
    if start then
      return M.deleteSelection(value, session), true
    end
    if session.fieldCaret > 0 then
      value = string.sub(value, 1, session.fieldCaret - 1) .. string.sub(value, session.fieldCaret + 1)
      session.fieldCaret = session.fieldCaret - 1
      session.fieldSelAnchor = session.fieldCaret
    end
    return value, true
  end

  if key == "delete" then
    local start, stop = M.selectionRange(session)
    if start then
      return M.deleteSelection(value, session), true
    end
    if session.fieldCaret < #value then
      value = string.sub(value, 1, session.fieldCaret) .. string.sub(value, session.fieldCaret + 2)
      session.fieldSelAnchor = session.fieldCaret
    end
    return value, true
  end

  local shift = isShiftDown()
  if key == "left" then
    moveCaret(session, value, session.fieldCaret - 1, shift)
    return value, true
  end
  if key == "right" then
    moveCaret(session, value, session.fieldCaret + 1, shift)
    return value, true
  end
  if key == "home" then
    moveCaret(session, value, 0, shift)
    return value, true
  end
  if key == "end" then
    moveCaret(session, value, #value, shift)
    return value, true
  end

  return value, false
end

function M.caretVisible()
  if not (love and love.timer and love.timer.getTime) then
    return true
  end
  return math.floor(love.timer.getTime() * 2) % 2 == 0
end

function M.drawContents(field, value, theme, session, disabled)
  value = value or ""
  local alpha = disabled and 0.35 or 1
  local textX = field.x + TEXT_PAD_X
  local textY = field.y + TEXT_PAD_Y

  if field.focused and session and not disabled then
    local selStart, selEnd = M.selectionRange(session)
    if selStart and love and love.graphics and love.graphics.getFont then
      local font = love.graphics.getFont()
      local x1 = textX + font:getWidth(string.sub(value, 1, selStart))
      local x2 = textX + font:getWidth(string.sub(value, 1, selEnd))
      love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 0.35)
      love.graphics.rectangle("fill", x1, field.y + 2, math.max(1, x2 - x1), field.h - 4)
    end
  end

  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], alpha)
  love.graphics.print(value, textX, textY)

  if field.focused and session and not disabled and M.caretVisible() then
    if love and love.graphics and love.graphics.getFont then
      local font = love.graphics.getFont()
      local caret = session.fieldCaret or #value
      local caretX = textX + font:getWidth(string.sub(value, 1, caret))
      love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], alpha)
      love.graphics.rectangle("fill", caretX, field.y + 3, 1, field.h - 6)
    end
  end
end

return M
