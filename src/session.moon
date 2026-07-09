create = (opts) ->
  opts = opts or {}
  {
    appliedRuleId: opts.ruleId
    appliedThemeId: opts.themeId
    appliedPatternId: opts.patternId
    gridMode: "auto"
    draftRulePresetId: nil
    draftRuleString: nil
    draftRuleFocus: false
    draftThemePresetId: nil
    draftThemeColors: nil
    draftThemeFocus: nil
    draftPatternId: nil
  }

resetRuleDraft = (session, rule) ->
  session.draftRulePresetId = rule.name
  session.draftRuleString = rule.rulestring
  session.draftRuleFocus = false

resetThemeDraft = (session, theme, themes) ->
  session.draftThemePresetId = theme.name
  session.draftThemeColors = themes.colorsToHex theme
  session.draftThemeFocus = nil

return {
  create: create, resetRuleDraft: resetRuleDraft, resetThemeDraft: resetThemeDraft
}
