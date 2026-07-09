local M = {}

function M.create(opts)
  opts = opts or {}
  return {
    appliedRuleId = opts.ruleId,
    appliedThemeId = opts.themeId,
    appliedPatternId = opts.patternId,
    gridMode = "auto",
    draftRuleId = nil,
    draftThemeId = nil,
    draftPatternId = nil,
  }
end

return M
