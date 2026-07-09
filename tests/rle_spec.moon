assert = require "tests.assert"
rle = require "src.patterns.rle"
test = require("tests.spec_helper").test

hasCell = (cells, col, row) ->
  for _, cell in ipairs cells
    return true if cell[1] == col and cell[2] == row
  false

test "parse glider rle with header and comments", ->
  pattern = rle.parse [[
#N Glider
#C classic spaceship
x = 3, y = 3, rule = B3/S23
bob$2bo$3o!
]]
  assert.equal pattern.name, "Glider"
  assert.equal pattern.rulestring, "B3/S23"
  assert.equal #pattern.cells, 5
  assert.isTrue hasCell(pattern.cells, 1, 0)
  assert.isTrue hasCell(pattern.cells, 2, 1)
  assert.isTrue hasCell(pattern.cells, 0, 2)
  assert.isTrue hasCell(pattern.cells, 1, 2)
  assert.isTrue hasCell(pattern.cells, 2, 2)

test "parse row breaks and run counts", ->
  pattern = rle.parse [[
x = 5, y = 4
2o$3b2o$5b$4o!
]]
  assert.equal #pattern.cells, 8
  assert.isTrue hasCell(pattern.cells, 0, 0)
  assert.isTrue hasCell(pattern.cells, 1, 0)
  assert.isTrue hasCell(pattern.cells, 3, 1)
  assert.isTrue hasCell(pattern.cells, 4, 1)
  assert.isTrue hasCell(pattern.cells, 0, 3)
  assert.isTrue hasCell(pattern.cells, 3, 3)

test "parse rejects invalid token", ->
  ok = pcall rle.parse, "x = 1, y = 1\na!"
  assert.isFalse ok

test "parse rejects missing terminator", ->
  ok = pcall rle.parse, "x = 1, y = 1\no"
  assert.isFalse ok

test "parse lifeview rle asset with comment lines", ->
  file = io.open "patterns/lifeview.rle", "r"
  text = file\read "*a"
  file\close!
  pattern = rle.parse text
  assert.equal pattern.rulestring, "B3/S23"
  assert.equal #pattern.cells, 9
