rules = require "src.rules"
widgets = require "src.ui.pane_widgets"

title = "Rules"

PANE_PAD_X = 12
BTN_H = 22
BTN_GAP = 6
FIELD_H = 22
GAP = 8
APPLY_W = 72
PRESET_MIN_W = 72

estimatePresetWidth = (name) ->
  if love and love.graphics and love.graphics.getFont
    return math.max PRESET_MIN_W, love.graphics.getFont!\getWidth(name) + 16
  math.max PRESET_MIN_W, #name * 7 + 16

matchPresetId = (rulestring) ->
  for _, name in ipairs rules.list!
    return name if rules.get(name).rulestring == rulestring
  "custom"

layout = (rect, contentY, session) ->
  presetButtons = {}
  x = rect.x + PANE_PAD_X
  for _, name in ipairs rules.list!
    table.insert presetButtons, {
      id: name, label: name, w: estimatePresetWidth(name), h: BTN_H
    }
  widgets.layoutRow x, contentY, presetButtons, BTN_GAP
  fieldY = contentY + BTN_H + GAP + 14
  field =
    x: rect.x + PANE_PAD_X
    y: fieldY
    w: rect.w - PANE_PAD_X * 2
    h: FIELD_H
    value: session.draftRuleString or ""
    focused: session.draftRuleFocus
  apply =
    id: "apply", label: "Apply"
    x: rect.x + PANE_PAD_X
    y: fieldY + FIELD_H + GAP
    w: APPLY_W, h: BTN_H
  presetButtons: presetButtons, field: field, apply: apply

measure = (config) ->
  contentH = BTN_H + GAP + 14 + FIELD_H + GAP + BTN_H
  contentW = config.paneWidth or 360
  presetW = PANE_PAD_X * 2
  for _, name in ipairs rules.list!
    presetW += estimatePresetWidth(name) + BTN_GAP
  presetW -= BTN_GAP
  math.max(contentW, presetW), contentH

draw = (rect, contentY, theme, _config, session) ->
  ui = layout rect, contentY, session
  for _, button in ipairs ui.presetButtons
    widgets.drawButton button, theme, session.draftRulePresetId == button.id
  widgets.drawField "Rulestring:", ui.field, theme
  widgets.drawButton ui.apply, theme, false

mousepressed = (rect, contentY, session, x, y) ->
  ui = layout rect, contentY, session
  return "apply_rule" if widgets.hitButton(ui.apply, x, y)
  for _, button in ipairs ui.presetButtons
    if widgets.hitButton button, x, y
      rule = rules.get button.id
      session.draftRulePresetId = rule.name
      session.draftRuleString = rule.rulestring
      session.draftRuleFocus = false
      return
  if widgets.hitField ui.field, x, y
    session.draftRuleFocus = true
    return
  session.draftRuleFocus = false

textinput = (session, text) ->
  return unless session.draftRuleFocus
  ch = text\upper!
  if ch\match "^[%dB/S]$"
    session.draftRuleString = (session.draftRuleString or "") .. ch
    session.draftRulePresetId = matchPresetId session.draftRuleString

keypressed = (session, key) ->
  return false unless session.draftRuleFocus
  if key == "backspace"
    value = session.draftRuleString or ""
    session.draftRuleString = value\sub 1, #value - 1
    session.draftRulePresetId = matchPresetId session.draftRuleString
    return true
  false

apply = (session) ->
  rules.tryFromRulestring session.draftRuleString or ""

return {
  title: title, measure: measure, draw: draw, mousepressed: mousepressed
  textinput: textinput, keypressed: keypressed, apply: apply
}
