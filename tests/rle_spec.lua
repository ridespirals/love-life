local assert = require("tests.assert")
local rle = require("src.patterns.rle")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

local function hasCell(cells, col, row)
  for _, cell in ipairs(cells) do
    if cell[1] == col and cell[2] == row then
      return true
    end
  end
  return false
end

test("parse glider rle with header and comments", function()
  local pattern = rle.parse([[
#N Glider
#C classic spaceship
x = 3, y = 3, rule = B3/S23
bob$2bo$3o!
]])

  assert.equal(pattern.name, "Glider")
  assert.equal(pattern.rulestring, "B3/S23")
  assert.equal(#pattern.cells, 5)
  assert.isTrue(hasCell(pattern.cells, 1, 0))
  assert.isTrue(hasCell(pattern.cells, 2, 1))
  assert.isTrue(hasCell(pattern.cells, 0, 2))
  assert.isTrue(hasCell(pattern.cells, 1, 2))
  assert.isTrue(hasCell(pattern.cells, 2, 2))
end)

test("parse row breaks and run counts", function()
  local pattern = rle.parse([[
x = 5, y = 4
2o$3b2o$5b$4o!
]])

  assert.equal(#pattern.cells, 8)
  assert.isTrue(hasCell(pattern.cells, 0, 0))
  assert.isTrue(hasCell(pattern.cells, 1, 0))
  assert.isTrue(hasCell(pattern.cells, 3, 1))
  assert.isTrue(hasCell(pattern.cells, 4, 1))
  assert.isTrue(hasCell(pattern.cells, 0, 3))
  assert.isTrue(hasCell(pattern.cells, 3, 3))
end)

test("parse rejects invalid token", function()
  local ok = pcall(rle.parse, "x = 1, y = 1\na!")
  assert.isFalse(ok)
end)

test("parse rejects missing terminator", function()
  local ok = pcall(rle.parse, "x = 1, y = 1\no")
  assert.isFalse(ok)
end)

test("parse lifeview rle asset with comment lines", function()
  local file = io.open("patterns/lifeview.rle", "r")
  local text = file:read("*a")
  file:close()

  local pattern = rle.parse(text)
  assert.equal(pattern.rulestring, "B3/S23")
  assert.equal(#pattern.cells, 9)
end)
