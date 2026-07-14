local themes = require("src.themes")
local widgets = require("src.ui.pane_widgets")

local M = {}

M.title = "Themes"

local PANE_PAD_X = 12
local BTN_H = 22
local BTN_GAP = 6
local FIELD_H = 22
local GAP = 8
local SAVE_W = 72
local DELETE_W = 72
local PRESET_MIN_W = 72
local LABEL_W = 88
-- Preset row wraps at this width regardless of final pane width (kept in
-- sync between measure() and layout() so the pane never grows wider than
-- the screen with a large theme catalog — see plan/04-ui-shell-and-panes.md).
local PRESET_ROW_MAX_W = 480
local SWATCH_W = 22
local SWATCH_GAP = 6
local MIN_FIELD_W = 120

local colorFields = { "alive", "dead", "grid", "background", "accent" }

local function draftPreviewColor(colors, key)
  if not colors then
    return nil
  end
  return themes.colorFromHex(colors[key])
end

local function estimatePresetWidth(name)
  if love and love.graphics and love.graphics.getFont then
    return math.max(PRESET_MIN_W, love.graphics.getFont():getWidth(name) + 16)
  end
  return math.max(PRESET_MIN_W, #name * 7 + 16)
end

local function buildPresetButtons()
  local presetButtons = {}
  for _, name in ipairs(themes.list()) do
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

  local fields = {}
  local fieldY = contentY + presetBlockH + GAP
  local colors = session.draftThemeColors or {}
  local fieldW = rect.w - PANE_PAD_X * 2 - LABEL_W - SWATCH_GAP - SWATCH_W
  local swatchX = rect.x + PANE_PAD_X + LABEL_W + fieldW + SWATCH_GAP
  for _, key in ipairs(colorFields) do
    fields[#fields + 1] = {
      id = key,
      label = key .. ":",
      labelX = rect.x + PANE_PAD_X,
      x = rect.x + PANE_PAD_X + LABEL_W,
      y = fieldY,
      w = fieldW,
      h = FIELD_H,
      value = colors[key] or (key == "accent" and "" or "#000000"),
      focused = session.draftThemeFocus == key,
      swatch = {
        x = swatchX,
        y = fieldY,
        w = SWATCH_W,
        h = FIELD_H,
      },
    }
    fieldY = fieldY + FIELD_H + 6
  end

  local nameField = {
    id = "name",
    label = "Name:",
    labelX = rect.x + PANE_PAD_X,
    x = rect.x + PANE_PAD_X + LABEL_W,
    y = fieldY,
    w = fieldW,
    h = FIELD_H,
    value = session.draftThemeName or "",
    focused = session.draftThemeFocus == "name",
  }
  fieldY = fieldY + FIELD_H + GAP

  local save = {
    id = "save",
    label = "Save",
    x = rect.x + PANE_PAD_X,
    y = fieldY,
    w = SAVE_W,
    h = BTN_H,
  }
  local delete = {
    id = "delete",
    label = "Delete",
    x = save.x + SAVE_W + BTN_GAP,
    y = fieldY,
    w = DELETE_W,
    h = BTN_H,
    enabled = themes.isUser(session.draftThemePresetId),
  }

  return {
    presetButtons = presetButtons,
    fields = fields,
    nameField = nameField,
    save = save,
    delete = delete,
  }
end

local function applyActionIfValid(session)
  if M.apply(session) then
    return "apply_theme"
  end
end

function M.measure(config)
  local presetButtons = buildPresetButtons()
  local _, presetW, presetBlockH = widgets.layoutGrid(0, 0, presetButtons, BTN_GAP, PRESET_ROW_MAX_W)

  local fieldBlock = (#colorFields + 1) * (FIELD_H + 6)
  local contentH = presetBlockH + GAP + fieldBlock + GAP + BTN_H
  local contentW = config.paneWidth or 360
  local minFieldRowW = LABEL_W + MIN_FIELD_W + SWATCH_GAP + SWATCH_W + PANE_PAD_X * 2
  local btnRowW = PANE_PAD_X * 2 + SAVE_W + DELETE_W + BTN_GAP

  return math.max(contentW, presetW + PANE_PAD_X * 2, minFieldRowW, btnRowW), contentH
end

function M.draw(rect, contentY, theme, _config, session)
  local ui = layout(rect, contentY, session)
  local colors = session.draftThemeColors

  for _, button in ipairs(ui.presetButtons) do
    widgets.drawButton(button, theme, session.draftThemePresetId == button.id)
  end

  for _, field in ipairs(ui.fields) do
    widgets.drawField(field.label, field, theme)
    widgets.drawColorSwatch(field.swatch, draftPreviewColor(colors, field.id), theme)
  end

  widgets.drawField(ui.nameField.label, ui.nameField, theme)
  widgets.drawButton(ui.save, theme, false)
  widgets.drawButton(ui.delete, theme, false, not ui.delete.enabled)
end

function M.mousepressed(rect, contentY, session, x, y)
  local ui = layout(rect, contentY, session)

  if widgets.hitButton(ui.save, x, y) then
    return "save_theme"
  end
  if ui.delete.enabled and widgets.hitButton(ui.delete, x, y) then
    return "delete_theme"
  end

  for _, button in ipairs(ui.presetButtons) do
    if widgets.hitButton(button, x, y) then
      local preset = themes.get(button.id)
      session.draftThemePresetId = preset.name
      session.draftThemeColors = themes.colorsToHex(preset)
      session.draftThemeName = preset.name
      session.draftThemeFocus = nil
      return "apply_theme"
    end
  end

  for _, field in ipairs(ui.fields) do
    if widgets.hitField(field, x, y) then
      session.draftThemeFocus = field.id
      return
    end
  end

  if widgets.hitField(ui.nameField, x, y) then
    session.draftThemeFocus = "name"
    return
  end

  session.draftThemeFocus = nil
end

function M.textinput(session, text)
  local focus = session.draftThemeFocus
  if not focus then
    return
  end

  if focus == "name" then
    local ch = text
    if ch:match("^[%w%s_%-]$") then
      session.draftThemeName = (session.draftThemeName or "") .. ch
    end
    return
  end

  if not session.draftThemeColors then
    return
  end

  local ch = text:lower()
  if ch:match("^[0-9a-f#]$") then
    local value = session.draftThemeColors[focus] or "#"
    if #value < 7 then
      session.draftThemeColors[focus] = value .. ch
      session.draftThemePresetId = "custom"
      return applyActionIfValid(session)
    end
  end
end

function M.keypressed(session, key)
  local focus = session.draftThemeFocus
  if not focus then
    return false
  end

  if focus == "name" then
    if key == "backspace" then
      local value = session.draftThemeName or ""
      session.draftThemeName = value:sub(1, #value - 1)
      return true
    end
    return false
  end

  if not session.draftThemeColors then
    return false
  end

  if key == "backspace" then
    local value = session.draftThemeColors[focus] or ""
    session.draftThemeColors[focus] = value:sub(1, #value - 1)
    session.draftThemePresetId = "custom"
    return applyActionIfValid(session) or true
  end

  return false
end

function M.apply(session)
  local colors = session.draftThemeColors
  if not colors then
    return
  end

  local accent = colors.accent
  if not accent or accent == "" then
    accent = nil
  end

  return themes.tryBuild({
    name = session.draftThemePresetId or "custom",
    alive = colors.alive,
    dead = colors.dead,
    grid = colors.grid,
    background = colors.background,
    accent = accent,
  })
end

return M
