local rules = require("src.rules")
local widgets = require("src.ui.pane_widgets")

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
  local x = rect.x + PANE_PAD_X
  local _, _, presetBlockH = widgets.layoutGrid(x, contentY, presetButtons, BTN_GAP, PRESET_ROW_MAX_W)

  local fieldY = contentY + presetBlockH + GAP
  local field = {
    x = rect.x + PANE_PAD_X,
    y = fieldY,
    w = rect.w - PANE_PAD_X * 2,
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
  local _, presetW, presetBlockH = widgets.layoutGrid(0, 0, presetButtons, BTN_GAP, PRESET_ROW_MAX_W)

  local contentH = presetBlockH + GAP + FIELD_H + GAP + FIELD_H + GAP + BTN_H
  local contentW = config.paneWidth or 360
  local btnRowW = PANE_PAD_X * 2 + APPLY_W + SAVE_W + DELETE_W + BTN_GAP * 2

  return math.max(contentW, presetW + PANE_PAD_X * 2, btnRowW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)

  for _, button in ipairs(ui.presetButtons) do
    widgets.drawButton(button, theme, session.draftRulePresetId == button.id)
  end

  widgets.drawField("Rulestring:", ui.field, theme)
  widgets.drawField(ui.nameField.label, ui.nameField, theme)
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
    return
  end
  if widgets.hitField(ui.nameField, x, y) then
    session.draftRuleFocus = "name"
    return
  end

  session.draftRuleFocus = false
end

function M.textinput(session, text)
  if session.draftRuleFocus == "name" then
    local ch = text
    if ch:match("^[%w%s_%-]$") then
      session.draftRuleName = (session.draftRuleName or "") .. ch
    end
    return
  end

  if session.draftRuleFocus ~= "rulestring" then
    return
  end

  local ch = text:upper()
  if ch:match("^[%dB/S]$") then
    session.draftRuleString = (session.draftRuleString or "") .. ch
    session.draftRulePresetId = matchPresetId(session.draftRuleString)
  end
end

function M.keypressed(session, key)
  if session.draftRuleFocus == "name" then
    if key == "backspace" then
      local value = session.draftRuleName or ""
      session.draftRuleName = value:sub(1, #value - 1)
      return true
    end
    return false
  end

  if session.draftRuleFocus ~= "rulestring" then
    return false
  end

  if key == "backspace" then
    local value = session.draftRuleString or ""
    session.draftRuleString = value:sub(1, #value - 1)
    session.draftRulePresetId = matchPresetId(session.draftRuleString)
    return true
  end

  return false
end

function M.apply(session)
  return rules.tryFromRulestring(session.draftRuleString or "")
end

return M
