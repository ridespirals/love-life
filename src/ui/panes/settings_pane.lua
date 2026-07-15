local widgets = require("src.ui.pane_widgets")
local text_field = require("src.ui.text_field")

local M = {}

M.title = "Settings"

local PANE_PAD_X = 12
local BTN_H = 22
local BTN_GAP = 6
local FIELD_H = 22
local GAP = 8
local APPLY_W = 72
local MODE_BTN_W = 72
local ANIM_BTN_W = 48
local LABEL_W = 88
local HINT_H = 16

local HINT = "Fullscreen: F11 or Alt+Enter"

local function parsePositiveInt(text)
  if not text or text == "" then
    return nil
  end
  local value = tonumber(text)
  if not value then
    return nil
  end
  value = math.floor(value)
  if value < 1 then
    return nil
  end
  return value
end

local function modeButtons()
  return {
    { id = "auto", label = "Auto", w = MODE_BTN_W, h = BTN_H },
    { id = "forced", label = "Forced", w = MODE_BTN_W, h = BTN_H },
  }
end

local function animButtons()
  return {
    { id = "on", label = "On", w = ANIM_BTN_W, h = BTN_H },
    { id = "off", label = "Off", w = ANIM_BTN_W, h = BTN_H },
  }
end

local function layout(rect, contentY, session)
  local buttons = modeButtons()
  local buttonsX = rect.x + PANE_PAD_X + LABEL_W
  widgets.layoutRow(buttonsX, contentY, buttons, BTN_GAP)
  local modeBlockH = BTN_H

  local animY = contentY + modeBlockH + GAP
  local animBtns = animButtons()
  widgets.layoutRow(buttonsX, animY, animBtns, BTN_GAP)
  local animBlockH = BTN_H

  local tileY = animY + animBlockH + GAP
  local tileField = {
    id = "tile",
    label = "Tile:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = tileY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftTileSize or "",
    focused = session.draftGridFocus == "tile",
  }

  local rowsY = tileY + FIELD_H + GAP
  local rowsField = {
    id = "rows",
    label = "Rows:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = rowsY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftRows or "",
    focused = session.draftGridFocus == "rows",
    enabled = session.draftGridMode == "forced",
  }

  local colsY = rowsY + FIELD_H + GAP
  local colsField = {
    id = "cols",
    label = "Cols:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = colsY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftCols or "",
    focused = session.draftGridFocus == "cols",
    enabled = session.draftGridMode == "forced",
  }

  local btnY = colsY + FIELD_H + GAP
  local apply = {
    id = "apply",
    label = "Apply",
    x = rect.x + PANE_PAD_X,
    y = btnY,
    w = APPLY_W,
    h = BTN_H,
  }

  return {
    modeButtons = buttons,
    animButtons = animBtns,
    tileField = tileField,
    rowsField = rowsField,
    colsField = colsField,
    apply = apply,
    hintY = btnY + BTN_H + GAP,
  }
end

function M.measure(config)
  local contentH = BTN_H + GAP + BTN_H + GAP + FIELD_H + GAP + FIELD_H + GAP + FIELD_H + GAP + BTN_H + GAP + HINT_H
  local contentW = config.paneWidth or 360
  local modeW = LABEL_W + MODE_BTN_W * 2 + BTN_GAP
  local animW = LABEL_W + ANIM_BTN_W * 2 + BTN_GAP
  local fieldRowW = PANE_PAD_X * 2 + LABEL_W + 120

  return math.max(contentW, modeW + PANE_PAD_X * 2, animW + PANE_PAD_X * 2, fieldRowW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)

  local fontH = 12
  if love and love.graphics and love.graphics.getFont then
    fontH = love.graphics.getFont():getHeight()
  end
  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 1)
  love.graphics.print(
    "Grid mode:",
    rect.x + PANE_PAD_X,
    contentY + math.floor((BTN_H - fontH) / 2)
  )

  for _, button in ipairs(ui.modeButtons) do
    widgets.drawButton(button, theme, session.draftGridMode == button.id)
  end

  local animY = contentY + BTN_H + GAP
  love.graphics.print(
    "Animate:",
    rect.x + PANE_PAD_X,
    animY + math.floor((BTN_H - fontH) / 2)
  )
  for _, button in ipairs(ui.animButtons) do
    local selected = (session.draftStepAnimEnabled and button.id == "on")
      or (not session.draftStepAnimEnabled and button.id == "off")
    widgets.drawButton(button, theme, selected)
  end

  widgets.drawField(ui.tileField.label, ui.tileField, theme, false, session)
  widgets.drawField(ui.rowsField.label, ui.rowsField, theme, not ui.rowsField.enabled, session)
  widgets.drawField(ui.colsField.label, ui.colsField, theme, not ui.colsField.enabled, session)
  widgets.drawButton(ui.apply, theme, false)

  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 0.7)
  love.graphics.print(HINT, rect.x + PANE_PAD_X, ui.hintY)
end

local function draftValue(session, focus)
  if focus == "tile" then
    return session.draftTileSize or ""
  end
  if focus == "rows" then
    return session.draftRows or ""
  end
  return session.draftCols or ""
end

local function setDraftValue(session, focus, value)
  if focus == "tile" then
    session.draftTileSize = value
  elseif focus == "rows" then
    session.draftRows = value
  else
    session.draftCols = value
  end
end

function M.mousepressed(rect, contentY, session, x, y)
  local ui = layout(rect, contentY, session)

  if widgets.hitButton(ui.apply, x, y) then
    return "apply_grid"
  end

  for _, button in ipairs(ui.modeButtons) do
    if widgets.hitButton(button, x, y) then
      session.draftGridMode = button.id
      session.draftGridFocus = nil
      return
    end
  end

  for _, button in ipairs(ui.animButtons) do
    if widgets.hitButton(button, x, y) then
      session.draftStepAnimEnabled = button.id == "on"
      session.draftGridFocus = nil
      return
    end
  end

  if widgets.hitField(ui.tileField, x, y) then
    session.draftGridFocus = "tile"
    widgets.focusField(session, session.draftTileSize or "", ui.tileField, x)
    return
  end
  if ui.rowsField.enabled and widgets.hitField(ui.rowsField, x, y) then
    session.draftGridFocus = "rows"
    widgets.focusField(session, session.draftRows or "", ui.rowsField, x)
    return
  end
  if ui.colsField.enabled and widgets.hitField(ui.colsField, x, y) then
    session.draftGridFocus = "cols"
    widgets.focusField(session, session.draftCols or "", ui.colsField, x)
    return
  end

  session.draftGridFocus = nil
  text_field.pointerUp(session)
end

function M.mousemoved(rect, contentY, session, x, y)
  local focus = session.draftGridFocus
  if not session.fieldDragging or not focus then
    return
  end
  local ui = layout(rect, contentY, session)
  if focus == "tile" then
    text_field.pointerDrag(session, session.draftTileSize or "", ui.tileField, x)
  elseif focus == "rows" then
    text_field.pointerDrag(session, session.draftRows or "", ui.rowsField, x)
  elseif focus == "cols" then
    text_field.pointerDrag(session, session.draftCols or "", ui.colsField, x)
  end
end

function M.mousereleased(session)
  text_field.pointerUp(session)
end

function M.textinput(session, text)
  local focus = session.draftGridFocus
  if not focus then
    return
  end
  if focus == "rows" or focus == "cols" then
    if session.draftGridMode ~= "forced" then
      return
    end
  end

  local ch = text
  if ch:match("^%d$") then
    local value = text_field.insert(session, draftValue(session, focus), ch)
    setDraftValue(session, focus, value)
  end
end

function M.keypressed(session, key)
  if key == "return" and session.draftGridFocus then
    return "apply_grid"
  end

  local focus = session.draftGridFocus
  if not focus then
    return false
  end
  if (focus == "rows" or focus == "cols") and session.draftGridMode ~= "forced" then
    return false
  end

  local value, consumed = text_field.keypressed(session, draftValue(session, focus), key)
  if consumed then
    setDraftValue(session, focus, value)
    return true
  end
  return false
end

function M.apply(session, config)
  local tileSize = parsePositiveInt(session.draftTileSize)
  if not tileSize then
    return nil
  end

  local mode = session.draftGridMode == "forced" and "forced" or "auto"
  local stepAnimEnabled = session.draftStepAnimEnabled ~= false
  if mode == "auto" then
    return {
      mode = "auto",
      tileSize = tileSize,
      stepAnimEnabled = stepAnimEnabled,
    }
  end

  local rows = parsePositiveInt(session.draftRows)
  local cols = parsePositiveInt(session.draftCols)
  if not rows or not cols then
    return nil
  end

  return {
    mode = "forced",
    tileSize = tileSize,
    rows = rows,
    cols = cols,
    forcedRows = rows,
    forcedCols = cols,
    forcedTileSize = tileSize,
    stepAnimEnabled = stepAnimEnabled,
  }
end

return M
