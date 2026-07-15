local assert = require("tests.assert")
local layout = require("src.layout")
local session = require("src.session")
local settings_pane = require("src.ui.panes.settings_pane")
local test = require("tests.spec_helper").test

test("computeBoardLayout centers fixed board in viewport", function()
  local board = layout.computeBoardLayout(720, 508, 40, 60, 12, 28)
  assert.equal(board.boardWidth, 720)
  assert.equal(board.boardHeight, 480)
  assert.equal(board.offsetX, 0)
  assert.equal(board.offsetY, 0)
end)

test("computeBoardLayout letterboxes when board exceeds viewport", function()
  local board = layout.computeBoardLayout(400, 300, 80, 80, 8, 28)
  assert.equal(board.boardWidth, 640)
  assert.equal(board.boardHeight, 640)
  assert.equal(board.offsetX, -120)
  assert.equal(board.offsetY, -184)
end)

test("resetGridDraft copies applied grid dimensions", function()
  local state = session.create({ gridMode = "forced" })
  state.gridMode = "forced"
  local cfg = { tileSize = 8, rows = 80, cols = 80 }
  session.resetGridDraft(state, cfg)
  assert.equal(state.draftGridMode, "forced")
  assert.equal(state.draftTileSize, "8")
  assert.equal(state.draftRows, "80")
  assert.equal(state.draftCols, "80")
end)

test("settings apply accepts auto mode with tile size", function()
  local state = session.create()
  state.draftGridMode = "auto"
  state.draftTileSize = "16"
  local applied = settings_pane.apply(state, {})
  assert.equal(applied.mode, "auto")
  assert.equal(applied.tileSize, 16)
end)

test("settings apply accepts forced mode with rows cols and tile", function()
  local state = session.create()
  state.draftGridMode = "forced"
  state.draftTileSize = "8"
  state.draftRows = "80"
  state.draftCols = "80"
  local applied = settings_pane.apply(state, {})
  assert.equal(applied.mode, "forced")
  assert.equal(applied.rows, 80)
  assert.equal(applied.cols, 80)
  assert.equal(applied.tileSize, 8)
end)

test("settings apply rejects invalid numeric drafts", function()
  local state = session.create()
  state.draftGridMode = "forced"
  state.draftTileSize = "0"
  state.draftRows = "80"
  state.draftCols = "80"
  assert.equal(settings_pane.apply(state, {}), nil)
end)
