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
local PRESET_MIN_W = 72

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

local function layout(rect, contentY, session)
  local presetButtons = {}
  local x = rect.x + PANE_PAD_X
  for _, name in ipairs(rules.list()) do
    presetButtons[#presetButtons + 1] = {
      id = name,
      label = name,
      w = estimatePresetWidth(name),
      h = BTN_H,
    }
  end
  widgets.layoutRow(x, contentY, presetButtons, BTN_GAP)

  local fieldY = contentY + BTN_H + GAP + 14
  local field = {
    x = rect.x + PANE_PAD_X,
    y = fieldY,
    w = rect.w - PANE_PAD_X * 2,
    h = FIELD_H,
    value = session.draftRuleString or "",
    focused = session.draftRuleFocus,
  }

  local apply = {
    id = "apply",
    label = "Apply",
    x = rect.x + PANE_PAD_X,
    y = fieldY + FIELD_H + GAP,
    w = APPLY_W,
    h = BTN_H,
  }

  return {
    presetButtons = presetButtons,
    field = field,
    apply = apply,
  }
end

function M.measure(config)
  local contentH = BTN_H + GAP + 14 + FIELD_H + GAP + BTN_H
  local contentW = config.paneWidth or 360

  local presetW = PANE_PAD_X * 2
  for _, name in ipairs(rules.list()) do
    presetW = presetW + estimatePresetWidth(name) + BTN_GAP
  end
  presetW = presetW - BTN_GAP

  return math.max(contentW, presetW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)

  for _, button in ipairs(ui.presetButtons) do
    widgets.drawButton(button, theme, session.draftRulePresetId == button.id)
  end

  widgets.drawField("Rulestring:", ui.field, theme)
  widgets.drawButton(ui.apply, theme, false)
end

function M.mousepressed(rect, contentY, session, x, y)
  local ui = layout(rect, contentY, session)

  if widgets.hitButton(ui.apply, x, y) then
    return "apply_rule"
  end

  for _, button in ipairs(ui.presetButtons) do
    if widgets.hitButton(button, x, y) then
      local rule = rules.get(button.id)
      session.draftRulePresetId = rule.name
      session.draftRuleString = rule.rulestring
      session.draftRuleFocus = false
      return
    end
  end

  if widgets.hitField(ui.field, x, y) then
    session.draftRuleFocus = true
    return
  end

  session.draftRuleFocus = false
end

function M.textinput(session, text)
  if not session.draftRuleFocus then
    return
  end

  local ch = text:upper()
  if ch:match("^[%dB/S]$") then
    session.draftRuleString = (session.draftRuleString or "") .. ch
    session.draftRulePresetId = matchPresetId(session.draftRuleString)
  end
end

function M.keypressed(session, key)
  if not session.draftRuleFocus then
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
