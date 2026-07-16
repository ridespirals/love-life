-- Always-visible floating toolbar (upper-left). Not part of the docked-pane system.
local widgets = require("src.ui.pane_widgets")

local M = {}

local TOOLS = {
  { id = "pan", kind = "tool", tooltip = "Mouse mode: pan screen" },
  { id = "draw", kind = "tool", tooltip = "Mouse mode: draw" },
  { id = "zoom_in", kind = "action", tooltip = "Zoom In" },
  { id = "zoom_out", kind = "action", tooltip = "Zoom out" },
}

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function contains(rect, x, y)
  return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function M.getButtons(config)
  local margin = config.toolbarMargin or 12
  local size = config.toolbarButtonSize or 32
  local gap = 6
  local pad = 6
  local count = #TOOLS
  local panelW = pad * 2 + count * size + (count - 1) * gap
  local panelH = pad * 2 + size
  local panelX = margin
  local panelY = margin

  local buttons = {}
  local x = panelX + pad
  local y = panelY + pad
  for _, spec in ipairs(TOOLS) do
    buttons[#buttons + 1] = {
      id = spec.id,
      kind = spec.kind,
      tooltip = spec.tooltip,
      x = x,
      y = y,
      w = size,
      h = size,
    }
    x = x + size + gap
  end

  return {
    x = panelX,
    y = panelY,
    w = panelW,
    h = panelH,
    buttons = buttons,
  }
end

local function drawPanIcon(button, theme)
  local cx = button.x + button.w / 2
  local cy = button.y + button.h / 2
  local arm = math.floor(button.w * 0.28)
  setColor(theme.alive, 1)
  love.graphics.line(cx - arm, cy, cx + arm, cy)
  love.graphics.line(cx, cy - arm, cx, cy + arm)
  love.graphics.line(cx - arm, cy, cx - arm + 4, cy - 3)
  love.graphics.line(cx - arm, cy, cx - arm + 4, cy + 3)
  love.graphics.line(cx + arm, cy, cx + arm - 4, cy - 3)
  love.graphics.line(cx + arm, cy, cx + arm - 4, cy + 3)
  love.graphics.line(cx, cy - arm, cx - 3, cy - arm + 4)
  love.graphics.line(cx, cy - arm, cx + 3, cy - arm + 4)
  love.graphics.line(cx, cy + arm, cx - 3, cy + arm - 4)
  love.graphics.line(cx, cy + arm, cx + 3, cy + arm - 4)
end

local function drawPencilIcon(button, theme)
  local x = button.x + button.w * 0.28
  local y = button.y + button.h * 0.62
  local len = button.w * 0.42
  setColor(theme.alive, 1)
  love.graphics.line(x, y, x + len, y - len)
  love.graphics.line(x + len - 2, y - len - 2, x + len + 2, y - len + 2)
  love.graphics.polygon(
    "fill",
    x - 1,
    y + 1,
    x + 4,
    y + 1,
    x + 1,
    y + 4
  )
end

local function drawZoomLabel(button, theme, label)
  setColor(theme.alive, 1)
  love.graphics.printf(label, button.x, button.y + math.floor(button.h / 2) - 6, button.w, "center")
end

function M.draw(theme, config, session)
  local panel = M.getButtons(config)
  local active = session and session.activeTool or nil
  local pointerX = session and session.pointerX
  local pointerY = session and session.pointerY

  setColor(theme.dead, 0.92)
  love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h)
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", panel.x + 0.5, panel.y + 0.5, panel.w, panel.h)

  for _, button in ipairs(panel.buttons) do
    local selected = button.kind == "tool" and active == button.id
    local hovered = pointerX ~= nil and contains(button, pointerX, pointerY)
    if selected then
      setColor(theme.alive, 0.25)
      love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
    elseif hovered then
      widgets.drawHoverWash(button, theme, 0.14)
    end
    setColor(theme.grid, 1)
    love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.w, button.h)

    if button.id == "pan" then
      drawPanIcon(button, theme)
    elseif button.id == "draw" then
      drawPencilIcon(button, theme)
    elseif button.id == "zoom_in" then
      drawZoomLabel(button, theme, "+")
    elseif button.id == "zoom_out" then
      drawZoomLabel(button, theme, "−")
    end
  end
end

-- Returns { text, rect } for the hovered toolbar button, or nil.
function M.tooltipAt(config, x, y)
  if x == nil or y == nil then
    return nil
  end
  local panel = M.getButtons(config)
  for _, button in ipairs(panel.buttons) do
    if contains(button, x, y) then
      return {
        text = button.tooltip,
        rect = button,
      }
    end
  end
  return nil
end

function M.hitTest(config, x, y)
  local panel = M.getButtons(config)
  if not contains(panel, x, y) then
    return nil
  end
  for _, button in ipairs(panel.buttons) do
    if contains(button, x, y) then
      return button.id
    end
  end
  -- Click on panel chrome still consumes the hit so board tools don't fire under it.
  return "panel"
end

function M.contains(config, x, y)
  local panel = M.getButtons(config)
  return contains(panel, x, y)
end

return M
