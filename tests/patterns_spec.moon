assert = require "tests.assert"
grid = require "src.grid"
patterns = require "src.patterns"
specHelper = require "tests.spec_helper"
test = specHelper.test
aliveCount = specHelper.aliveCount
withLoveMock = specHelper.withLoveMock

test "list returns catalog ids including rle assets", ->
  assert.equal table.concat(patterns.list!, ","),
    "backrake_1,beacon,blinker,bomber,circle_of_fire,copperhead,cottonmouth,diamond,fireship,glider,gosper_glider_gun,lifeview,loafer,moose_antlers,noahs_ark,pulsar,pulsar_on_pentadecathlon_i,sidecar,still_life_tagalong"

test "get falls back to glider for unknown pattern", ->
  pattern = patterns.get "does_not_exist"
  assert.equal pattern.id, "glider"

test "get loads rle pattern through love.filesystem", ->
  withLoveMock {
    getInfo: (path, kind) ->
      assert.equal path, "patterns/test_rle.rle"
      assert.equal kind, "file"
      type: "file"
    read: (path) ->
      assert.equal path, "patterns/test_rle.rle"
      "x = 3, y = 3, rule = B3/S23\nbob$2bo$3o!"
  }, ->
    pattern = patterns.get "test_rle"
    assert.equal pattern.id, "test_rle"
    assert.equal pattern.rulestring, "B3/S23"
    assert.equal #pattern.cells, 5

test "apply centers glider pattern on board", ->
  world = grid.create 7, 7
  patterns.apply world, "glider"
  assert.isTrue grid.isAlive(world, 3, 4)
  assert.isTrue grid.isAlive(world, 4, 5)
  assert.isTrue grid.isAlive(world, 5, 3)
  assert.isTrue grid.isAlive(world, 5, 4)
  assert.isTrue grid.isAlive(world, 5, 5)

test "stamp with empty cells clears board", ->
  world = grid.create 5, 5
  grid.setAlive world, 2, 2, true
  patterns.stamp world, { id: "empty", name: "Empty", cells: {} }
  assert.equal aliveCount(world), 0

test "apply loads and centers pulsar from rle file", ->
  withLoveMock {
    getInfo: (path, kind) ->
      file = io.open path, "r"
      if file
        file\close!
        return type: kind or "file"
      nil
    read: (path) ->
      file = _G.assert io.open(path, "r")
      text = file\read "*a"
      file\close!
      text
  }, ->
    world = grid.create 40, 60
    patterns.apply world, "pulsar"
    count = aliveCount world
    minRow, maxRow = world.rows, 1
    minCol, maxCol = world.cols, 1
    for row = 1, world.rows
      for col = 1, world.cols
        if grid.isAlive(world, row, col)
          minRow = row if row < minRow
          maxRow = row if row > maxRow
          minCol = col if col < minCol
          maxCol = col if col > maxCol
    assert.isTrue count > 20
    assert.isTrue math.abs((minRow - 1) - (world.rows - maxRow)) <= 1
    assert.isTrue math.abs((minCol - 1) - (world.cols - maxCol)) <= 1
