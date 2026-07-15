local assert = require("tests.assert")
local text_field = require("src.ui.text_field")
local test = require("tests.spec_helper").test

local function charWidth(text)
  return #text * 8
end

local function session()
  return {
    fieldCaret = 0,
    fieldSelStart = nil,
    fieldSelEnd = nil,
    fieldSelAnchor = 0,
    fieldDragging = false,
  }
end

test("insert replaces selection and places caret after text", function()
  local state = session()
  text_field.onFocus(state, "hello")
  state.fieldSelStart = 1
  state.fieldSelEnd = 3
  state.fieldCaret = 3
  local value = text_field.insert(state, "hello", "X")
  assert.equal(value, "hXlo")
  assert.equal(state.fieldCaret, 2)
  assert.equal(state.fieldSelStart, nil)
end)

test("backspace deletes selection in one step", function()
  local state = session()
  text_field.onFocus(state, "abcdef")
  state.fieldSelStart = 1
  state.fieldSelEnd = 4
  state.fieldCaret = 4
  local value = text_field.keypressed(state, "abcdef", "backspace")
  assert.equal(value, "aef")
  assert.equal(state.fieldCaret, 1)
end)

test("indexAtX maps click position to caret index", function()
  local value = "abcd"
  assert.equal(text_field.indexAtX(charWidth, value, 10, 10), 0)
  assert.equal(text_field.indexAtX(charWidth, value, 10, 14), 0)
  assert.equal(text_field.indexAtX(charWidth, value, 10, 18), 1)
  assert.equal(text_field.indexAtX(charWidth, value, 10, 50), 4)
end)

test("selectAll highlights the full value", function()
  local state = session()
  text_field.selectAll(state, "tile")
  assert.equal(state.fieldSelStart, 0)
  assert.equal(state.fieldSelEnd, 4)
  assert.equal(state.fieldCaret, 4)
end)

test("right arrow moves caret and clears selection", function()
  local state = session()
  text_field.onFocus(state, "ab", { caret = 0 })
  state.fieldSelStart = 0
  state.fieldSelEnd = 2
  local value, consumed = text_field.keypressed(state, "ab", "right")
  assert.equal(consumed, true)
  assert.equal(value, "ab")
  assert.equal(state.fieldCaret, 1)
  assert.equal(state.fieldSelStart, nil)
end)
