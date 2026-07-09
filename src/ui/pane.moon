themes = require "src.themes"

PANE_PAD_X = 12
PANE_PAD_Y = 10
TITLE_GAP = 22
LINE_HEIGHT = 16
CLOSE_RESERVE = 32

titleFont = nil

paneModules =
  rule: require "src.ui.panes.rule_pane"
  theme: require "src.ui.panes.theme_pane"

paneDefs =
  pattern:
    title: "Patterns"
    lines: { "Pattern catalog, New / Edit / Save — Phase 4." }
  settings:
    title: "Settings"
    lines: {
      "Grid mode, tile size, auto-fit — Phase 5."
      "Fullscreen: F11 or Alt+Enter"
    }

getPaneDef = (state) ->
  mod = paneModules[state.openId]
  return { title: mod.title } if mod
  paneDefs[state.openId]

getPaneModule = (state) ->
  paneModules[state.openId]

contains = (rect, x, y) ->
  x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h

setColor = (color, alpha) ->
  love.graphics.setColor color[1], color[2], color[3], alpha or 1

configPx = (config, key, default) ->
  value = config[key]
  return value if value ~= nil
  default

lerpColor = (color, target, amount) ->
  {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }

panelDepth = (config, w, h) ->
  depth = configPx config, "tileDepthAlivePx", 3
  minDim = math.min w, h
  return 0 if minDim < 4
  math.min depth, math.floor(minDim / 3)

drawExtrudedPanel = (x, y, w, h, theme, config) ->
  face = theme.dead
  depth = panelDepth config, w, h
  if depth <= 0
    setColor face, 0.98
    love.graphics.rectangle "fill", x, y, w, h
    return
  faceW = w - depth
  faceH = h - depth
  shadow = themes.extrusionShadow theme, face, false
  highlight = lerpColor face, { 1, 1, 1 }, 0.1
  setColor shadow, 0.98
  love.graphics.rectangle "fill", x + depth, y + h - depth, faceW, depth
  love.graphics.rectangle "fill", x + w - depth, y + depth, depth, faceH
  setColor face, 0.98
  love.graphics.rectangle "fill", x, y, faceW, faceH
  setColor highlight, 0.98
  love.graphics.rectangle "fill", x, y, faceW, 1
  love.graphics.rectangle "fill", x, y, 1, faceH

withTitleFont = (fn) ->
  unless love and love.graphics and love.graphics.getFont
    fn!
    return
  previous = love.graphics.getFont!
  titleSize = previous\getHeight! + 2
  if not titleFont or titleFont\getHeight! ~= titleSize
    titleFont = love.graphics.newFont titleSize
  love.graphics.setFont titleFont
  fn!
  love.graphics.setFont previous

estimateTextWidth = (text) ->
  if love and love.graphics and love.graphics.getFont
    return love.graphics.getFont!\getWidth text
  #text * 7

measureContent = (state, config) ->
  def = getPaneDef state
  minW = configPx config, "paneWidth", 360
  minH = configPx config, "paneHeight", 120
  titleW = estimateTextWidth(def.title) + PANE_PAD_X * 2 + CLOSE_RESERVE
  mod = getPaneModule state
  if mod
    contentW, contentH = mod.measure config
    w = math.max minW, titleW, contentW
    h = math.max minH, PANE_PAD_Y + TITLE_GAP + contentH + PANE_PAD_Y
    return w, h
  bodyW = PANE_PAD_X * 2
  for _, line in ipairs def.lines
    bodyW = math.max bodyW, estimateTextWidth(line) + PANE_PAD_X * 2
  w = math.max minW, titleW, bodyW
  h = math.max minH, PANE_PAD_Y + TITLE_GAP + #def.lines * LINE_HEIGHT + PANE_PAD_Y
  w, h

layoutPaneRect = (config, state) ->
  paneW, paneH = measureContent state, config
  windowW = select 1, love.graphics.getDimensions!
  margin = configPx config, "paneScreenMargin", 8
  anchor = state.anchor or { x: margin, y: getViewportHeight(config), w: 100, h: 0 }
  paneX = anchor.x
  paneX = anchor.x + anchor.w - paneW if paneX + paneW > windowW - margin
  paneX = math.max margin, math.min(paneX, windowW - margin - paneW)
  paneY = math.max margin, anchor.y - paneH
  x: math.floor(paneX), y: paneY, w: paneW, h: paneH

drawFlatPanel = (theme, rect) ->
  setColor theme.dead, 0.98
  love.graphics.rectangle "fill", rect.x, rect.y, rect.w, rect.h

drawPanel = (theme, config, rect) ->
  drawExtrudedPanel rect.x, rect.y, rect.w, rect.h, theme, config

create = ->
  openId: nil, anchor: nil

open = (state, id, anchor) ->
  if paneDefs[id] or paneModules[id]
    state.openId = id
    state.anchor = anchor

close = (state) ->
  state.openId = nil
  state.anchor = nil

toggle = (state, id, anchor) ->
  if state.openId == id
    close state
  else
    open state, id, anchor

isOpen = (state) ->
  state.openId ~= nil

getOpenId = (state) ->
  state.openId

getHeight = (config, state) ->
  return 0 unless state.openId
  _, h = measureContent state, config
  h

capturesInput = (state) ->
  state.openId ~= nil

getViewportHeight = (config) ->
  _, height = love.graphics.getDimensions!
  height - config.statusBarHeight

getRect = (config, state) ->
  return unless state.openId
  layoutPaneRect config, state

getCloseButton = (config, state) ->
  rect = getRect config, state
  return unless rect
  size = 20
  x: rect.x + rect.w - size - 8, y: rect.y + 6, w: size, h: size

hitTestClose = (config, state, x, y) ->
  closeBtn = getCloseButton config, state
  if closeBtn and contains(closeBtn, x, y)
    return true

hitTestPane = (config, state, x, y) ->
  rect = getRect config, state
  if rect and contains(rect, x, y)
    return true

drawBackdrop = (state, config) ->
  return unless state.openId
  width, height = love.graphics.getDimensions!
  alpha = configPx config, "paneBackdropAlpha", 0.55
  setColor { 0, 0, 0 }, alpha
  love.graphics.rectangle "fill", 0, 0, width, height

draw = (state, theme, config, session) ->
  return unless state.openId
  def = getPaneDef state
  return unless def
  drawBackdrop state, config
  rect = getRect config, state
  anchor = state.anchor
  drawPanel theme, config, rect
  drawFlatPanel theme, anchor if anchor
  withTitleFont ->
    setColor theme.alive, 1
    love.graphics.print def.title, rect.x + PANE_PAD_X, rect.y + PANE_PAD_Y
  contentY = rect.y + PANE_PAD_Y + TITLE_GAP
  mod = getPaneModule state
  if mod
    mod.draw rect, contentY, theme, config, session
  else
    setColor theme.alive, 1
    textY = contentY
    for _, line in ipairs def.lines
      love.graphics.print line, rect.x + PANE_PAD_X, textY
      textY += LINE_HEIGHT
  closeBtn = getCloseButton config, state
  setColor theme.grid, 1
  love.graphics.rectangle "line", closeBtn.x + 0.5, closeBtn.y + 0.5, closeBtn.w, closeBtn.h
  setColor theme.alive, 1
  love.graphics.printf "×", closeBtn.x, closeBtn.y + 2, closeBtn.w, "center"

mousepressed = (state, session, x, y, theme, config) ->
  mod = getPaneModule state
  return unless mod
  rect = getRect config, state
  contentY = rect.y + PANE_PAD_Y + TITLE_GAP
  mod.mousepressed rect, contentY, session, x, y, theme, config

keypressed = (state, session, key) ->
  mod = getPaneModule state
  return false unless mod and mod.keypressed
  mod.keypressed session, key

textinput = (state, session, text) ->
  mod = getPaneModule state
  return unless mod and mod.textinput
  mod.textinput session, text

return {
  create: create, open: open, close: close, toggle: toggle
  isOpen: isOpen, getOpenId: getOpenId, getHeight: getHeight
  capturesInput: capturesInput, getViewportHeight: getViewportHeight
  getRect: getRect, getCloseButton: getCloseButton
  hitTestClose: hitTestClose, hitTestPane: hitTestPane
  drawBackdrop: drawBackdrop, draw: draw
  mousepressed: mousepressed, keypressed: keypressed, textinput: textinput
}
