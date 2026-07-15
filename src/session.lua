local M = {}

function M.create(opts)
  opts = opts or {}
  return {
    appliedRuleId = opts.ruleId,
    appliedThemeId = opts.themeId,
    appliedPatternId = opts.patternId,
    gridMode = "auto",
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
  }
end

function M.resetRuleDraft(session, rule)
  session.draftRulePresetId = rule.name
  session.draftRuleString = rule.rulestring
  session.draftRuleName = rule.name
  session.draftRuleFocus = false
end

function M.resetPatternDraft(session, patternId)
  session.draftPatternId = patternId
  session.draftPatternName = patternId
  session.draftPatternFocus = nil
end

function M.resetThemeDraft(session, theme, themes)
  session.draftThemePresetId = theme.name
  session.draftThemeColors = themes.colorsToHex(theme)
  session.draftThemeName = theme.name
  session.draftThemeFocus = nil
end

return M
