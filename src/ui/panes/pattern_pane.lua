local patterns = require("src.patterns")
local widgets = require("src.ui.pane_widgets")
local text_field = require("src.ui.text_field")

local M = {}

M.title = "Patterns"

local PANE_PAD_X = 12
local BTN_H = 22
local BTN_GAP = 6
local FIELD_H = 22
local GAP = 8
local APPLY_W = 72
local CLEAR_W = 72
local SAVE_W = 72
local DELETE_W = 72
local PRESET_MIN_W = 72
local PRESET_ROW_MAX_W = 480
local LABEL_W = 88
local HINT_H = 16

local HINT = "Board drawing (paused): left-drag paints, right-drag erases."

local function estimatePresetWidth(name)
  if love and love.graphics and love.graphics.getFont then
    return math.max(PRESET_MIN_W, love.graphics.getFont():getWidth(name) + 16)
  end
  return math.max(PRESET_MIN_W, #name * 7 + 16)
end

local function buildPresetButtons()
  local presetButtons = {}
  for _, id in ipairs(patterns.list()) do
    presetButtons[#presetButtons + 1] = {
      id = id,
      label = id,
      w = estimatePresetWidth(id),
      h = BTN_H,
    }
  end
  return presetButtons
end

local function layout(rect, contentY, session)
  local presetButtons = buildPresetButtons()
  local x = rect.x + PANE_PAD_X
  local _, _, presetBlockH = widgets.layoutGrid(x, contentY, presetButtons, BTN_GAP, PRESET_ROW_MAX_W)

  local nameY = contentY + presetBlockH + GAP
  local nameField = {
    id = "name",
    label = "Name:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = nameY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftPatternName or "",
    focused = session.draftPatternFocus == "name",
  }

  local btnY = nameY + FIELD_H + GAP
  local apply = {
    id = "apply",
    label = "Apply",
    x = rect.x + PANE_PAD_X,
    y = btnY,
    w = APPLY_W,
    h = BTN_H,
  }
  local clear = {
    id = "clear",
    label = "Clear",
    x = apply.x + APPLY_W + BTN_GAP,
    y = btnY,
    w = CLEAR_W,
    h = BTN_H,
  }
  local save = {
    id = "save",
    label = "Save",
    x = clear.x + CLEAR_W + BTN_GAP,
    y = btnY,
    w = SAVE_W,
    h = BTN_H,
  }
  local delete = {
    id = "delete",
    label = "Delete",
    x = save.x + SAVE_W + BTN_GAP,
    y = btnY,
    w = DELETE_W,
    h = BTN_H,
    enabled = patterns.isUser(session.draftPatternId),
  }

  local hintY = btnY + BTN_H + GAP

  return {
    presetButtons = presetButtons,
    nameField = nameField,
    apply = apply,
    clear = clear,
    save = save,
    delete = delete,
    hintY = hintY,
  }
end

function M.measure(config)
  local presetButtons = buildPresetButtons()
  local _, presetW, presetBlockH = widgets.layoutGrid(0, 0, presetButtons, BTN_GAP, PRESET_ROW_MAX_W)

  local contentH = presetBlockH + GAP + FIELD_H + GAP + BTN_H + GAP + HINT_H
  local contentW = config.paneWidth or 360
  local btnRowW = PANE_PAD_X * 2 + APPLY_W + CLEAR_W + SAVE_W + DELETE_W + BTN_GAP * 3

  return math.max(contentW, presetW + PANE_PAD_X * 2, btnRowW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)

  for _, button in ipairs(ui.presetButtons) do
    widgets.drawButton(
      button,
      theme,
      session.draftPatternId == button.id,
      false,
      widgets.isHovered(button, session)
    )
  end

  widgets.drawField(ui.nameField.label, ui.nameField, theme, false, session)
  widgets.drawButton(ui.apply, theme, false, false, widgets.isHovered(ui.apply, session))
  widgets.drawButton(ui.clear, theme, false, false, widgets.isHovered(ui.clear, session))
  widgets.drawButton(ui.save, theme, false, false, widgets.isHovered(ui.save, session))
  widgets.drawButton(ui.delete, theme, false, not ui.delete.enabled, widgets.isHovered(ui.delete, session))

  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 0.7)
  love.graphics.print(HINT, rect.x + PANE_PAD_X, ui.hintY)
end

function M.mousepressed(rect, contentY, session, x, y)
  local ui = layout(rect, contentY, session)

  if widgets.hitButton(ui.apply, x, y) then
    return "apply_pattern"
  end
  if widgets.hitButton(ui.clear, x, y) then
    return "clear_board"
  end
  if widgets.hitButton(ui.save, x, y) then
    return "save_pattern"
  end
  if ui.delete.enabled and widgets.hitButton(ui.delete, x, y) then
    return "delete_pattern"
  end

  for _, button in ipairs(ui.presetButtons) do
    if widgets.hitButton(button, x, y) then
      session.draftPatternId = button.id
      session.draftPatternName = button.id
      session.draftPatternFocus = nil
      return
    end
  end

  if widgets.hitField(ui.nameField, x, y) then
    session.draftPatternFocus = "name"
    widgets.focusField(session, session.draftPatternName or "", ui.nameField, x)
    return
  end

  session.draftPatternFocus = nil
  text_field.pointerUp(session)
end

function M.mousemoved(rect, contentY, session, x, y)
  if not session.fieldDragging or session.draftPatternFocus ~= "name" then
    return
  end
  local ui = layout(rect, contentY, session)
  text_field.pointerDrag(session, session.draftPatternName or "", ui.nameField, x)
end

function M.mousereleased(session)
  text_field.pointerUp(session)
end

function M.textinput(session, text)
  if session.draftPatternFocus ~= "name" then
    return
  end
  local ch = text
  if ch:match("^[%w%s_%-]$") then
    session.draftPatternName = text_field.insert(session, session.draftPatternName or "", ch)
  end
end

function M.keypressed(session, key)
  if key == "return" and session.draftPatternFocus == "name" then
    return "apply_pattern"
  end

  if session.draftPatternFocus ~= "name" then
    return false
  end
  local value, consumed = text_field.keypressed(session, session.draftPatternName or "", key)
  if consumed then
    session.draftPatternName = value
    return true
  end
  return false
end

return M
