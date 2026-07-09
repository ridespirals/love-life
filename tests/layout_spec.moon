assert = require "tests.assert"
layout = require "src.layout"
test = require("tests.spec_helper").test

test "computeGridSize fits rows and cols from viewport", ->
  rows, cols = layout.computeGridSize 720, 508, 12, 28
  assert.equal cols, 60
  assert.equal rows, 40

test "computeGridSize grows with larger window", ->
  smallRows, smallCols = layout.computeGridSize 400, 300, 12, 28
  largeRows, largeCols = layout.computeGridSize 800, 600, 12, 28
  assert.isTrue largeCols > smallCols
  assert.isTrue largeRows > smallRows

test "computeGridSize shrinks with smaller window", ->
  largeRows, largeCols = layout.computeGridSize 800, 600, 12, 28
  smallRows, smallCols = layout.computeGridSize 200, 150, 12, 28
  assert.isTrue smallCols < largeCols
  assert.isTrue smallRows < largeRows

test "computeGridSize clamps to at least 1x1", ->
  rows, cols = layout.computeGridSize 8, 8, 12, 28
  assert.equal rows, 1
  assert.equal cols, 1
