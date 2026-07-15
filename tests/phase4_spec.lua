local assert = require("tests.assert")
local session = require("src.session")
local pattern_pane = require("src.ui.panes.pattern_pane")
local test = require("tests.spec_helper").test

test("resetPatternDraft copies applied pattern id", function()
  local state = session.create({ patternId = "glider" })
  session.resetPatternDraft(state, "lifeview")
  assert.equal(state.draftPatternId, "lifeview")
  assert.equal(state.draftPatternName, "lifeview")
end)

test("pattern pane measure exceeds minimum height", function()
  local w, h = pattern_pane.measure({ paneWidth = 360 })
  assert.isTrue(w >= 360)
  assert.isTrue(h >= 80)
end)
