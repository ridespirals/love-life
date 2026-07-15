local themes = require("src.themes")

local M = {}

local PANE_PAD_X = 12
local PANE_PAD_Y = 10
local TITLE_GAP = 22
local LINE_HEIGHT = 16
local CLOSE_RESERVE = 32

local titleFont

local paneModules = {
  rule = require("src.ui.panes.rule_pane"),
  theme = require("src.ui.panes.theme_pane"),
  pattern = require("src.ui.panes.pattern_pane"),
}

local paneDefs = {
  settings = {
    title = "Settings",
    lines = {
      "Grid mode, tile size, auto-fit — Phase 5.",
      "Fullscreen: F11 or Alt+Enter",
    },
  },
}

local function getPaneDef(state)
  local mod = paneModules[state.openId]
  if mod then
    return { title = mod.title }
  end
  return paneDefs[state.openId]
end

local function getPaneModule(state)
  return paneModules[state.openId]
end

local function contains(rect, x, y)
  return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function configPx(config, key, default)
  local value = config[key]
  if value ~= nil then
    return value
  end
  return default
end

local function lerpColor(color, target, amount)
  return {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }
end

local function panelDepth(config, w, h)
  local depth = configPx(config, "tileDepthAlivePx", 3)
  local minDim = math.min(w, h)
  if minDim < 4 then
    return 0
  end
  return math.min(depth, math.floor(minDim / 3))
end

local function drawExtrudedPanel(x, y, w, h, theme, config)
  local face = theme.dead
  local depth = panelDepth(config, w, h)

  if depth <= 0 then
    setColor(face, 0.98)
    love.graphics.rectangle("fill", x, y, w, h)
    return
  end

  local faceW = w - depth
  local faceH = h - depth
  local shadow = themes.extrusionShadow(theme, face, false)
  local highlight = lerpColor(face, { 1, 1, 1 }, 0.1)

  setColor(shadow, 0.98)
  love.graphics.rectangle("fill", x + depth, y + h - depth, faceW, depth)
  love.graphics.rectangle("fill", x + w - depth, y + depth, depth, faceH)

  setColor(face, 0.98)
  love.graphics.rectangle("fill", x, y, faceW, faceH)

  setColor(highlight, 0.98)
  love.graphics.rectangle("fill", x, y, faceW, 1)
  love.graphics.rectangle("fill", x, y, 1, faceH)
end

local function withTitleFont(fn)
  if not love or not love.graphics or not love.graphics.getFont then
    fn()
    return
  end

  local previous = love.graphics.getFont()
  local titleSize = previous:getHeight() + 2
  -- LÖVE 11.x: no Font:setBold(); revisit when LÖVE 12 ships (see plan/04-ui-shell-and-panes.md).
  if not titleFont or titleFont:getHeight() ~= titleSize then
    titleFont = love.graphics.newFont(titleSize)
  end

  love.graphics.setFont(titleFont)
  fn()
  love.graphics.setFont(previous)
end

local function estimateTextWidth(text)
  if love and love.graphics and love.graphics.getFont then
    return love.graphics.getFont():getWidth(text)
  end
  return #text * 7
end

local function measureContent(state, config)
  local def = getPaneDef(state)
  local minW = configPx(config, "paneWidth", 360)
  local minH = configPx(config, "paneHeight", 120)

  local titleW = estimateTextWidth(def.title) + PANE_PAD_X * 2 + CLOSE_RESERVE
  local mod = getPaneModule(state)

  if mod then
    local contentW, contentH = mod.measure(config)
    local w = math.max(minW, titleW, contentW)
    local h = math.max(minH, PANE_PAD_Y + TITLE_GAP + contentH + PANE_PAD_Y)
    return w, h
  end

  local bodyW = PANE_PAD_X * 2
  for _, line in ipairs(def.lines) do
    bodyW = math.max(bodyW, estimateTextWidth(line) + PANE_PAD_X * 2)
  end

  local w = math.max(minW, titleW, bodyW)
  local h = math.max(minH, PANE_PAD_Y + TITLE_GAP + #def.lines * LINE_HEIGHT + PANE_PAD_Y)
  return w, h
end

local function layoutPaneRect(config, state)
  local paneW, paneH = measureContent(state, config)
  local windowW = select(1, love.graphics.getDimensions())
  local margin = configPx(config, "paneScreenMargin", 8)

  local anchor = state.anchor or { x = margin, y = M.getViewportHeight(config), w = 100, h = 0 }

  local paneX = anchor.x
  if paneX + paneW > windowW - margin then
    paneX = anchor.x + anchor.w - paneW
  end
  paneX = math.max(margin, math.min(paneX, windowW - margin - paneW))

  local paneY = anchor.y - paneH
  paneY = math.max(margin, paneY)

  return {
    x = math.floor(paneX),
    y = paneY,
    w = paneW,
    h = paneH,
  }
end

local function drawFlatPanel(theme, rect)
  setColor(theme.dead, 0.98)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
end

local function drawPanel(theme, config, rect)
  drawExtrudedPanel(rect.x, rect.y, rect.w, rect.h, theme, config)
end

function M.create()
  return {
    openId = nil,
    anchor = nil,
  }
end

function M.open(state, id, anchor)
  if paneDefs[id] or paneModules[id] then
    state.openId = id
    state.anchor = anchor
  end
end

function M.close(state)
  state.openId = nil
  state.anchor = nil
end

function M.toggle(state, id, anchor)
  if state.openId == id then
    M.close(state)
  else
    M.open(state, id, anchor)
  end
end

function M.isOpen(state)
  return state.openId ~= nil
end

function M.getOpenId(state)
  return state.openId
end

function M.getHeight(config, state)
  if not state.openId then
    return 0
  end
  local _, h = measureContent(state, config)
  return h
end

function M.capturesInput(state)
  return state.openId ~= nil
end

function M.getViewportHeight(config)
  local _, height = love.graphics.getDimensions()
  return height - config.statusBarHeight
end

function M.getRect(config, state)
  if not state.openId then
    return nil
  end
  return layoutPaneRect(config, state)
end

function M.getCloseButton(config, state)
  local rect = M.getRect(config, state)
  if not rect then
    return nil
  end

  local size = 20
  return {
    x = rect.x + rect.w - size - 8,
    y = rect.y + 6,
    w = size,
    h = size,
  }
end

function M.hitTestClose(config, state, x, y)
  local close = M.getCloseButton(config, state)
  if close and contains(close, x, y) then
    return true
  end
end

function M.hitTestPane(config, state, x, y)
  local rect = M.getRect(config, state)
  if rect and contains(rect, x, y) then
    return true
  end
end

function M.drawBackdrop(state, config)
  if not state.openId then
    return
  end

  local width, height = love.graphics.getDimensions()
  local alpha = configPx(config, "paneBackdropAlpha", 0.55)

  setColor({ 0, 0, 0 }, alpha)
  love.graphics.rectangle("fill", 0, 0, width, height)
end

function M.draw(state, theme, config, session)
  if not state.openId then
    return
  end

  local def = getPaneDef(state)
  if not def then
    return
  end

  M.drawBackdrop(state, config)

  local rect = M.getRect(config, state)
  local anchor = state.anchor

  drawPanel(theme, config, rect)
  if anchor then
    drawFlatPanel(theme, anchor)
  end

  withTitleFont(function()
    setColor(theme.alive, 1)
    love.graphics.print(def.title, rect.x + PANE_PAD_X, rect.y + PANE_PAD_Y)
  end)

  local contentY = rect.y + PANE_PAD_Y + TITLE_GAP
  local mod = getPaneModule(state)

  if mod then
    mod.draw(rect, contentY, theme, config, session)
  else
    setColor(theme.alive, 1)
    local textY = contentY
    for _, line in ipairs(def.lines) do
      love.graphics.print(line, rect.x + PANE_PAD_X, textY)
      textY = textY + LINE_HEIGHT
    end
  end

  local close = M.getCloseButton(config, state)
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", close.x + 0.5, close.y + 0.5, close.w, close.h)
  setColor(theme.alive, 1)
  love.graphics.printf("×", close.x, close.y + 2, close.w, "center")
end

function M.mousepressed(state, session, x, y, theme, config)
  local mod = getPaneModule(state)
  if not mod then
    return
  end

  local rect = M.getRect(config, state)
  local contentY = rect.y + PANE_PAD_Y + TITLE_GAP
  return mod.mousepressed(rect, contentY, session, x, y, theme, config)
end

function M.keypressed(state, session, key)
  local mod = getPaneModule(state)
  if not mod or not mod.keypressed then
    return false
  end
  return mod.keypressed(session, key)
end

function M.textinput(state, session, text)
  local mod = getPaneModule(state)
  if not mod or not mod.textinput then
    return
  end
  return mod.textinput(session, text)
end

return M
