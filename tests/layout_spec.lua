local assert = require("tests.assert")
local layout = require("src.layout")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

test("computeGridSize fits rows and cols from viewport", function()
  local rows, cols = layout.computeGridSize(720, 508, 12, 28)
  assert.equal(cols, 60)
  assert.equal(rows, 40)
end)

test("computeGridSize grows with larger window", function()
  local smallRows, smallCols = layout.computeGridSize(400, 300, 12, 28)
  local largeRows, largeCols = layout.computeGridSize(800, 600, 12, 28)
  assert.isTrue(largeCols > smallCols)
  assert.isTrue(largeRows > smallRows)
end)

test("computeGridSize shrinks with smaller window", function()
  local largeRows, largeCols = layout.computeGridSize(800, 600, 12, 28)
  local smallRows, smallCols = layout.computeGridSize(200, 150, 12, 28)
  assert.isTrue(smallCols < largeCols)
  assert.isTrue(smallRows < largeRows)
end)

test("computeGridSize clamps to at least 1x1", function()
  local rows, cols = layout.computeGridSize(8, 8, 12, 28)
  assert.equal(rows, 1)
  assert.equal(cols, 1)
end)
