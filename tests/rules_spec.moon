assert = require "tests.assert"
rules = require "src.rules"
test = require("tests.spec_helper").test

test "parse B3/S23 yields birth on 3 and survival on 2 or 3", ->
  parsed = rules.parse "B3/S23"
  assert.isTrue parsed.birth[3]
  assert.isFalse parsed.birth[2]
  assert.isTrue parsed.survival[2]
  assert.isTrue parsed.survival[3]
  assert.isFalse parsed.survival[4]

test "parse B3/S234 yields survival on 2, 3, or 4", ->
  parsed = rules.parse "B3/S234"
  assert.isTrue parsed.birth[3]
  assert.isTrue parsed.survival[2]
  assert.isTrue parsed.survival[3]
  assert.isTrue parsed.survival[4]
  assert.isFalse parsed.survival[5]

test "parse rejects invalid rulestrings", ->
  ok = pcall rules.parse, "invalid"
  assert.isFalse ok

test "get returns named presets", ->
  conway = rules.get "conway"
  assert.equal conway.name, "conway"
  assert.equal conway.rulestring, "B3/S23"
  antColony = rules.get "ant_colony"
  assert.equal antColony.name, "ant_colony"
  assert.equal antColony.rulestring, "B3/S234"

test "get falls back to conway for unknown names", ->
  fallback = rules.get "unknown"
  assert.equal fallback.name, "conway"

test "list returns sorted preset names", ->
  assert.equal table.concat(rules.list!, ","), "ant_colony,conway"

test "conway kills live cell with four neighbors", ->
  grid = require "src.grid"
  world = grid.create 3, 3
  conway = rules.get "conway"
  grid.setAlive world, 2, 2, true
  grid.setAlive world, 1, 2, true
  grid.setAlive world, 2, 1, true
  grid.setAlive world, 2, 3, true
  grid.setAlive world, 3, 2, true
  grid.computeNext world, conway
  assert.isFalse world.next[2][2]

test "ant colony survives live cell with four neighbors", ->
  grid = require "src.grid"
  world = grid.create 3, 3
  antColony = rules.get "ant_colony"
  grid.setAlive world, 2, 2, true
  grid.setAlive world, 1, 2, true
  grid.setAlive world, 2, 1, true
  grid.setAlive world, 2, 3, true
  grid.setAlive world, 3, 2, true
  grid.computeNext world, antColony
  assert.isTrue world.next[2][2]
