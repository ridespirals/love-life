assert = require "tests.assert"
grid = require "src.grid"
rules = require "src.rules"
stepAnimation = require "src.step_animation"
test = require("tests.spec_helper").test

config =
  stepAnimEnabled: true
  stepAnimPreviewSec: 0.1
  stepAnimCommitSec: 0.2

conway = rules.get "conway"

test "create starts idle", ->
  state = stepAnimation.create config
  assert.isTrue stepAnimation.isIdle(state)
  assert.isFalse stepAnimation.isAnimating(state)

test "begin enters preview phase", ->
  state = stepAnimation.create config
  stepAnimation.begin state
  assert.isFalse stepAnimation.isIdle(state)
  phase, t = stepAnimation.getPhaseT state
  assert.equal phase, "preview"
  assert.equal t, 0

test "update advances preview to commit to grid commit", ->
  state = stepAnimation.create config
  stepAnimation.begin state
  assert.equal stepAnimation.update(state, 0.05), nil
  phase = stepAnimation.getPhaseT state
  assert.equal phase, "preview"
  assert.equal stepAnimation.update(state, 0.06), nil
  phase = stepAnimation.getPhaseT state
  assert.equal phase, "commit"
  assert.equal stepAnimation.update(state, 0.1), nil
  assert.equal stepAnimation.update(state, 0.15), "commit"
  assert.isTrue stepAnimation.isIdle(state)

test "disabled begin requests immediate commit", ->
  state = stepAnimation.create stepAnimEnabled: false
  assert.equal stepAnimation.begin(state), "commit_immediate"
  assert.isTrue stepAnimation.isIdle(state)

test "begin while animating is ignored", ->
  state = stepAnimation.create config
  stepAnimation.begin state
  assert.equal stepAnimation.begin(state), nil

test "cancel returns to idle", ->
  state = stepAnimation.create config
  stepAnimation.begin state
  stepAnimation.cancel state
  assert.isTrue stepAnimation.isIdle(state)

test "getCellChange detects birth and death", ->
  world = grid.create 3, 3
  grid.setAlive world, 2, 2, true
  grid.computeNext world, conway
  assert.equal stepAnimation.getCellChange(world, 2, 2), "death"
  assert.equal stepAnimation.getCellChange(world, 1, 2), "unchanged"

test "speedScale greater than 1 completes phases faster", ->
  state = stepAnimation.create {
    stepAnimEnabled: true, stepAnimPreviewSec: 0.1, stepAnimCommitSec: 0.1
  }
  stepAnimation.setSpeedScale state, 4
  stepAnimation.begin state
  assert.equal stepAnimation.update(state, 0.03), nil
  assert.equal stepAnimation.getPhaseT(state), "commit"
  assert.equal stepAnimation.update(state, 0.03), "commit"
  assert.isTrue stepAnimation.isIdle(state)

test "getCellChange detects birth from three neighbors", ->
  world = grid.create 3, 3
  grid.setAlive world, 1, 1, true
  grid.setAlive world, 1, 2, true
  grid.setAlive world, 2, 1, true
  grid.computeNext world, conway
  assert.equal stepAnimation.getCellChange(world, 2, 2), "birth"

test "stepAnimSec splits into preview and commit when phases omitted", ->
  state = stepAnimation.create stepAnimEnabled: true, stepAnimSec: 0.3
  stepAnimation.begin state
  assert.equal stepAnimation.update(state, 0.11), nil
  assert.equal stepAnimation.getPhaseT(state), "preview"
  assert.equal stepAnimation.update(state, 0.02), nil
  assert.equal stepAnimation.getPhaseT(state), "commit"
  assert.equal stepAnimation.update(state, 0.19), "commit"
