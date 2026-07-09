themes = require "src.themes"
widgets = require "src.ui.pane_widgets"

title = "Themes"

PANE_PAD_X = 12
BTN_H = 22
BTN_GAP = 6
FIELD_H = 22
GAP = 8
APPLY_W = 72
PRESET_MIN_W = 72
LABEL_W = 88
PRESET_ROW_MAX_W = 480
SWATCH_W = 22
SWATCH_GAP = 6
MIN_FIELD_W = 120

colorFields = { "alive", "dead", "grid", "background", "accent" }

draftPreviewColor = (colors, key) ->
  return unless colors
  themes.colorFromHex colors[key]

estimatePresetWidth = (name) ->
  if love and love.graphics and love.graphics.getFont
    return math.max PRESET_MIN_W, love.graphics.getFont!\getWidth(name) + 16
  math.max PRESET_MIN_W, #name * 7 + 16

buildPresetButtons = ->
  presetButtons = {}
  for _, name in ipairs themes.list!
    table.insert presetButtons, {
      id: name, label: name, w: estimatePresetWidth(name), h: BTN_H
    }
  presetButtons

layout = (rect, contentY, session) ->
  presetButtons = buildPresetButtons!
  x = rect.x + PANE_PAD_X
  _, _, presetBlockH = widgets.layoutGrid x, contentY, presetButtons, BTN_GAP, PRESET_ROW_MAX_W
  fields = {}
  fieldY = contentY + presetBlockH + GAP
  colors = session.draftThemeColors or {}
  fieldW = rect.w - PANE_PAD_X * 2 - LABEL_W - SWATCH_GAP - SWATCH_W
  swatchX = rect.x + PANE_PAD_X + LABEL_W + fieldW + SWATCH_GAP
  for _, key in ipairs colorFields
    table.insert fields, {
      id: key
      label: "#{key}:"
      labelX: rect.x + PANE_PAD_X
      x: rect.x + PANE_PAD_X + LABEL_W
      y: fieldY
      w: fieldW
      h: FIELD_H
      value: colors[key] or (if key == "accent" then "" else "#000000")
      focused: session.draftThemeFocus == key
      swatch: { x: swatchX, y: fieldY, w: SWATCH_W, h: FIELD_H }
    }
    fieldY += FIELD_H + 6
  apply =
    id: "apply", label: "Apply"
    x: rect.x + PANE_PAD_X
    y: fieldY + GAP
    w: APPLY_W, h: BTN_H
  presetButtons: presetButtons, fields: fields, apply: apply

measure = (config) ->
  presetButtons = buildPresetButtons!
  _, presetW, presetBlockH = widgets.layoutGrid 0, 0, presetButtons, BTN_GAP, PRESET_ROW_MAX_W
  fieldBlock = #colorFields * (FIELD_H + 6)
  contentH = presetBlockH + GAP + fieldBlock + GAP + BTN_H
  contentW = config.paneWidth or 360
  minFieldRowW = LABEL_W + MIN_FIELD_W + SWATCH_GAP + SWATCH_W + PANE_PAD_X * 2
  math.max(contentW, presetW + PANE_PAD_X * 2, minFieldRowW), contentH

draw = (rect, contentY, theme, _config, session) ->
  ui = layout rect, contentY, session
  colors = session.draftThemeColors
  for _, button in ipairs ui.presetButtons
    widgets.drawButton button, theme, session.draftThemePresetId == button.id
  for _, field in ipairs ui.fields
    widgets.drawField field.label, field, theme
    widgets.drawColorSwatch field.swatch, draftPreviewColor(colors, field.id), theme
  widgets.drawButton ui.apply, theme, false

mousepressed = (rect, contentY, session, x, y) ->
  ui = layout rect, contentY, session
  return "apply_theme" if widgets.hitButton(ui.apply, x, y)
  for _, button in ipairs ui.presetButtons
    if widgets.hitButton button, x, y
      preset = themes.get button.id
      session.draftThemePresetId = preset.name
      session.draftThemeColors = themes.colorsToHex preset
      session.draftThemeFocus = nil
      return
  for _, field in ipairs ui.fields
    if widgets.hitField field, x, y
      session.draftThemeFocus = field.id
      return
  session.draftThemeFocus = nil

textinput = (session, text) ->
  focus = session.draftThemeFocus
  return unless focus and session.draftThemeColors
  ch = text\lower!
  if ch\match "^[0-9a-f#]$"
    value = session.draftThemeColors[focus] or "#"
    if #value < 7
      session.draftThemeColors[focus] = value .. ch
      session.draftThemePresetId = "custom"

keypressed = (session, key) ->
  focus = session.draftThemeFocus
  return false unless focus and session.draftThemeColors
  if key == "backspace"
    value = session.draftThemeColors[focus] or ""
    session.draftThemeColors[focus] = value\sub 1, #value - 1
    session.draftThemePresetId = "custom"
    return true
  false

apply = (session) ->
  colors = session.draftThemeColors
  return unless colors
  accent = colors.accent
  accent = nil if not accent or accent == ""
  themes.tryBuild {
    name: session.draftThemePresetId or "custom"
    alive: colors.alive, dead: colors.dead, grid: colors.grid
    background: colors.background, accent: accent
  }

return {
  title: title, measure: measure, draw: draw, mousepressed: mousepressed
  textinput: textinput, keypressed: keypressed, apply: apply
}
