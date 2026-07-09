assert = require "tests.assert"
playback = require "src.playback"
test = require("tests.spec_helper").test

test "create initializes paused state", ->
  state = playback.create 0.2
  assert.isFalse state.running
  assert.equal state.stepInterval, 0.2
  assert.equal state.accumulator, 0

test "play and pause toggle running flag", ->
  state = playback.create 0.2
  playback.play state
  assert.isTrue state.running
  playback.pause state
  assert.isFalse state.running

test "toggle flips running state", ->
  state = playback.create 0.2
  playback.toggle state
  assert.isTrue state.running
  playback.toggle state
  assert.isFalse state.running

test "update does nothing when paused", ->
  state = playback.create 0.1
  steps = 0
  playback.update state, 0.3, -> steps += 1
  assert.equal steps, 0
  assert.equal state.accumulator, 0

test "update advances once when passing interval", ->
  state = playback.create 0.1
  steps = 0
  playback.play state
  playback.update state, 0.12, -> steps += 1
  assert.equal steps, 1
  assert.isTrue math.abs(state.accumulator - 0.02) < 1e-9

test "update advances multiple times for large dt", ->
  state = playback.create 0.1
  steps = 0
  playback.play state
  playback.update state, 0.35, -> steps += 1
  assert.equal steps, 3
  assert.isTrue math.abs(state.accumulator - 0.05) < 1e-9

test "stepForward advances and resets accumulator", ->
  state = playback.create 0.1
  steps = 0
  state.accumulator = 0.09
  playback.stepForward state, -> steps += 1
  assert.equal steps, 1
  assert.equal state.accumulator, 0

test "setStepInterval updates playback timing", ->
  state = playback.create 0.2
  playback.setStepInterval state, 0.35
  assert.equal state.stepInterval, 0.35

test "restart pauses and resets accumulator", ->
  state = playback.create 0.1
  playback.play state
  state.accumulator = 0.09
  playback.restart state
  assert.isFalse state.running
  assert.equal state.accumulator, 0
