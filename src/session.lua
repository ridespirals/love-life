local text_field = require("src.ui.text_field")

local M = {}

function M.create(opts)
  opts = opts or {}
  return {
    appliedRuleId = opts.ruleId,
    appliedThemeId = opts.themeId,
    appliedPatternId = opts.patternId,
    gridMode = opts.gridMode or "auto",
    draftGridMode = nil,
    draftTileSize = nil,
    draftRows = nil,
    draftCols = nil,
    draftGridFocus = nil,
    draftRulePresetId = nil,
    draftRuleString = nil,
    draftRuleName = nil,
    draftRuleFocus = false,
    draftThemePresetId = nil,
    draftThemeColors = nil,
    draftThemeName = nil,
    draftThemeFocus = nil,
    draftPatternId = opts.patternId,
    draftPatternName = opts.patternId,
    draftPatternFocus = nil,
    fieldCaret = 0,
    fieldSelStart = nil,
    fieldSelEnd = nil,
    fieldSelAnchor = 0,
    fieldDragging = false,
  }
end

function M.resetRuleDraft(session, rule)
  session.draftRulePresetId = rule.name
  session.draftRuleString = rule.rulestring
  session.draftRuleName = rule.name
  session.draftRuleFocus = false
  text_field.onFocus(session, session.draftRuleString)
end

function M.resetPatternDraft(session, patternId)
  session.draftPatternId = patternId
  session.draftPatternName = patternId
  session.draftPatternFocus = nil
  text_field.onFocus(session, session.draftPatternName)
end

function M.resetThemeDraft(session, theme, themes)
  session.draftThemePresetId = theme.name
  session.draftThemeColors = themes.colorsToHex(theme)
  session.draftThemeName = theme.name
  session.draftThemeFocus = nil
  text_field.onFocus(session, session.draftThemeName)
end

function M.resetGridDraft(session, config)
  session.draftGridMode = session.gridMode
  session.draftTileSize = tostring(config.tileSize)
  session.draftRows = tostring(config.rows)
  session.draftCols = tostring(config.cols)
  session.draftGridFocus = nil
  text_field.onFocus(session, session.draftTileSize)
end

return M
