local rules = require("src.rules")
local widgets = require("src.ui.pane_widgets")
local text_field = require("src.ui.text_field")

local M = {}

M.title = "Rules"

local PANE_PAD_X = 12
local BTN_H = 22
local BTN_GAP = 6
local FIELD_H = 22
local GAP = 8
local APPLY_W = 72
local SAVE_W = 72
local DELETE_W = 72
local PRESET_MIN_W = 72
local PRESET_ROW_MAX_W = 480
local LABEL_W = 88

local function estimatePresetWidth(name)
  if love and love.graphics and love.graphics.getFont then
    return math.max(PRESET_MIN_W, love.graphics.getFont():getWidth(name) + 16)
  end
  return math.max(PRESET_MIN_W, #name * 7 + 16)
end

local function matchPresetId(rulestring)
  for _, name in ipairs(rules.list()) do
    if rules.get(name).rulestring == rulestring then
      return name
    end
  end
  return "custom"
end

local function buildPresetButtons()
  local presetButtons = {}
  for _, name in ipairs(rules.list()) do
    presetButtons[#presetButtons + 1] = {
      id = name,
      label = name,
      w = estimatePresetWidth(name),
      h = BTN_H,
    }
  end
  return presetButtons
end

local function layout(rect, contentY, session)
  local presetButtons = buildPresetButtons()
  local presetsX = rect.x + PANE_PAD_X + LABEL_W
  local presetMaxW = math.max(PRESET_MIN_W, rect.w - PANE_PAD_X * 2 - LABEL_W)
  local _, _, presetBlockH = widgets.layoutGrid(presetsX, contentY, presetButtons, BTN_GAP, presetMaxW)

  local fieldY = contentY + presetBlockH + GAP
  local field = {
    label = "Rulestring:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = fieldY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftRuleString or "",
    focused = session.draftRuleFocus == "rulestring",
  }

  local nameY = fieldY + FIELD_H + GAP
  local nameField = {
    id = "name",
    label = "Name:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = nameY,
    w = rect.w - PANE_PAD_X * 2 - LABEL_W,
    h = FIELD_H,
    value = session.draftRuleName or "",
    focused = session.draftRuleFocus == "name",
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
  local save = {
    id = "save",
    label = "Save",
    x = apply.x + APPLY_W + BTN_GAP,
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
    enabled = rules.isUser(session.draftRulePresetId),
  }

  return {
    presetButtons = presetButtons,
    field = field,
    nameField = nameField,
    apply = apply,
    save = save,
    delete = delete,
  }
end

function M.measure(config)
  local presetButtons = buildPresetButtons()
  local presetMaxW = math.max(PRESET_MIN_W, (config.paneWidth or 360) - PANE_PAD_X * 2 - LABEL_W)
  local _, presetW, presetBlockH = widgets.layoutGrid(0, 0, presetButtons, BTN_GAP, presetMaxW)

  local contentH = presetBlockH + GAP + FIELD_H + GAP + FIELD_H + GAP + BTN_H
  local contentW = config.paneWidth or 360
  local btnRowW = PANE_PAD_X * 2 + APPLY_W + SAVE_W + DELETE_W + BTN_GAP * 2
  local presetRowW = PANE_PAD_X * 2 + LABEL_W + presetW
  local fieldRowW = PANE_PAD_X * 2 + LABEL_W + 120

  return math.max(contentW, presetRowW, fieldRowW, btnRowW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)

  local fontH = 12
  if love and love.graphics and love.graphics.getFont then
    fontH = love.graphics.getFont():getHeight()
  end
  love.graphics.setColor(theme.alive[1], theme.alive[2], theme.alive[3], 1)
  love.graphics.print(
    "Preset:",
    rect.x + PANE_PAD_X,
    contentY + math.floor((BTN_H - fontH) / 2)
  )

  for _, button in ipairs(ui.presetButtons) do
    widgets.drawButton(button, theme, session.draftRulePresetId == button.id)
  end

  widgets.drawField(ui.field.label, ui.field, theme, false, session)
  widgets.drawField(ui.nameField.label, ui.nameField, theme, false, session)
  widgets.drawButton(ui.apply, theme, false)
  widgets.drawButton(ui.save, theme, false)
  widgets.drawButton(ui.delete, theme, false, not ui.delete.enabled)
end

function M.mousepressed(rect, contentY, session, x, y)
  local ui = layout(rect, contentY, session)

  if widgets.hitButton(ui.apply, x, y) then
    return "apply_rule"
  end
  if widgets.hitButton(ui.save, x, y) then
    return "save_rule"
  end
  if ui.delete.enabled and widgets.hitButton(ui.delete, x, y) then
    return "delete_rule"
  end

  for _, button in ipairs(ui.presetButtons) do
    if widgets.hitButton(button, x, y) then
      local rule = rules.get(button.id)
      session.draftRulePresetId = rule.name
      session.draftRuleString = rule.rulestring
      session.draftRuleName = rule.name
      session.draftRuleFocus = false
      return
    end
  end

  if widgets.hitField(ui.field, x, y) then
    session.draftRuleFocus = "rulestring"
    widgets.focusField(session, session.draftRuleString or "", ui.field, x)
    return
  end
  if widgets.hitField(ui.nameField, x, y) then
    session.draftRuleFocus = "name"
    widgets.focusField(session, session.draftRuleName or "", ui.nameField, x)
    return
  end

  session.draftRuleFocus = false
  text_field.pointerUp(session)
end

function M.mousemoved(rect, contentY, session, x, y)
  if not session.fieldDragging then
    return
  end
  local ui = layout(rect, contentY, session)
  if session.draftRuleFocus == "rulestring" then
    text_field.pointerDrag(session, session.draftRuleString or "", ui.field, x)
  elseif session.draftRuleFocus == "name" then
    text_field.pointerDrag(session, session.draftRuleName or "", ui.nameField, x)
  end
end

function M.mousereleased(session)
  text_field.pointerUp(session)
end

function M.textinput(session, text)
  if session.draftRuleFocus == "name" then
    local ch = text
    if ch:match("^[%w%s_%-]$") then
      session.draftRuleName = text_field.insert(session, session.draftRuleName or "", ch)
    end
    return
  end

  if session.draftRuleFocus ~= "rulestring" then
    return
  end

  local ch = text:upper()
  if ch:match("^[%dB/S]$") then
    session.draftRuleString = text_field.insert(session, session.draftRuleString or "", ch)
    session.draftRulePresetId = matchPresetId(session.draftRuleString)
  end
end

function M.keypressed(session, key)
  if session.draftRuleFocus == "name" then
    local value, consumed = text_field.keypressed(session, session.draftRuleName or "", key)
    if consumed then
      session.draftRuleName = value
      return true
    end
    return false
  end

  if session.draftRuleFocus ~= "rulestring" then
    return false
  end

  local value, consumed = text_field.keypressed(session, session.draftRuleString or "", key)
  if consumed then
    session.draftRuleString = value
    session.draftRulePresetId = matchPresetId(session.draftRuleString)
    return true
  end

  return false
end

function M.apply(session)
  return rules.tryFromRulestring(session.draftRuleString or "")
end

return M
