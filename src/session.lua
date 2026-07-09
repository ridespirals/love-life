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
    draftRuleFocus = false,
    draftThemePresetId = nil,
    draftThemeColors = nil,
    draftThemeFocus = nil,
    draftPatternId = nil,
  }
end

function M.resetRuleDraft(session, rule)
  session.draftRulePresetId = rule.name
  session.draftRuleString = rule.rulestring
  session.draftRuleFocus = false
end

function M.resetThemeDraft(session, theme, themes)
  session.draftThemePresetId = theme.name
  session.draftThemeColors = themes.colorsToHex(theme)
  session.draftThemeFocus = nil
end

return M
