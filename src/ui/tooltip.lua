-- Pane-styled floating tooltip that follows the pointer without covering its source.
local M = {}

local PAD_X = 8
local PAD_Y = 5
local CURSOR_GAP_X = 14
local CURSOR_GAP_Y = 18
local AVOID_GAP = 6

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function overlaps(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function measure(text)
  local font = love.graphics.getFont()
  return font:getWidth(text), font:getHeight()
end

-- Place tooltip near the cursor; if it would cover avoidRect, tuck it below that rect.
function M.layout(text, mouseX, mouseY, avoidRect, screenW, screenH)
  local textW, textH = measure(text)
  local w = textW + PAD_X * 2
  local h = textH + PAD_Y * 2
  local x = mouseX + CURSOR_GAP_X
  local y = mouseY + CURSOR_GAP_Y

  if avoidRect and overlaps(x, y, w, h, avoidRect.x, avoidRect.y, avoidRect.w, avoidRect.h) then
    x = avoidRect.x
    y = avoidRect.y + avoidRect.h + AVOID_GAP
  end

  if x + w > screenW - 4 then
    x = math.max(4, screenW - w - 4)
  end
  if y + h > screenH - 4 then
    y = math.max(4, mouseY - h - AVOID_GAP)
  end
  if x < 4 then
    x = 4
  end
  if y < 4 then
    y = 4
  end

  return { x = x, y = y, w = w, h = h, text = text }
end

function M.draw(theme, text, mouseX, mouseY, avoidRect)
  if not text or text == "" then
    return
  end

  local screenW, screenH = love.graphics.getDimensions()
  local box = M.layout(text, mouseX, mouseY, avoidRect, screenW, screenH)

  setColor(theme.dead, 0.96)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", box.x + 0.5, box.y + 0.5, box.w, box.h)
  setColor(theme.alive, 1)
  love.graphics.print(box.text, box.x + PAD_X, box.y + PAD_Y)
end

return M
