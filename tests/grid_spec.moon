assert = require "tests.assert"
grid = require "src.grid"
rules = require "src.rules"
test = require("tests.spec_helper").test
aliveCount = require("tests.spec_helper").aliveCount

conway = rules.get "conway"

test "empty board stays empty after computeNext", ->
  world = grid.create 3, 3
  grid.computeNext world, conway
  assert.equal aliveCount(world), 0

test "dead cell with exactly three neighbors is born", ->
  world = grid.create 3, 3
  grid.setAlive world, 1, 1, true
  grid.setAlive world, 1, 2, true
  grid.setAlive world, 2, 1, true
  grid.computeNext world, conway
  assert.isTrue world.next[2][2]

test "live cell with fewer than two neighbors dies", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 2, true
  grid.computeNext world, conway
  assert.isFalse world.next[2][2]

test "live cell with four or more neighbors dies", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 2, true
  grid.setAlive world, 1, 2, true
  grid.setAlive world, 2, 1, true
  grid.setAlive world, 2, 3, true
  grid.setAlive world, 3, 2, true
  grid.computeNext world, conway
  assert.isFalse world.next[2][2]

test "live cell with two or three neighbors survives", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 2, true
  grid.setAlive world, 2, 1, true
  grid.setAlive world, 1, 2, true
  grid.computeNext world, conway
  assert.isTrue world.next[2][2]

test "toroidal wrap counts vertical edge neighbors", ->
  world = grid.create 3, 3
  grid.setAlive world, 3, 1, true
  assert.equal grid.countNeighbors(world, 1, 1), 1

test "toroidal wrap counts horizontal edge neighbors", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 3, true
  assert.equal grid.countNeighbors(world, 2, 1), 1

test "blinker oscillates with period two", ->
  world = grid.create 5, 5
  grid.setAlive world, 3, 2, true
  grid.setAlive world, 3, 3, true
  grid.setAlive world, 3, 4, true
  grid.computeNext world, conway
  assert.isFalse world.next[3][2]
  assert.isTrue world.next[2][3]
  assert.isTrue world.next[3][3]
  assert.isTrue world.next[4][3]
  assert.isFalse world.next[3][4]
  grid.step world, conway
  assert.isTrue grid.isAlive(world, 2, 3)
  assert.isTrue grid.isAlive(world, 3, 3)
  assert.isTrue grid.isAlive(world, 4, 3)
  assert.isFalse grid.isAlive(world, 3, 2)
  assert.isFalse grid.isAlive(world, 3, 4)
  grid.step world, conway
  assert.isTrue grid.isAlive(world, 3, 2)
  assert.isTrue grid.isAlive(world, 3, 3)
  assert.isTrue grid.isAlive(world, 3, 4)
  assert.isFalse grid.isAlive(world, 2, 3)
  assert.isFalse grid.isAlive(world, 4, 3)

test "computeNext leaves current unchanged", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 2, true
  before = world.current[2][2]
  grid.computeNext world, conway
  assert.equal world.current[2][2], before
  assert.isFalse world.next[2][2]
