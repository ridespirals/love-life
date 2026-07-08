local assert = require("tests.assert")
local playback = require("src.playback")

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

test("create initializes paused state", function()
  local state = playback.create(0.2)
  assert.isFalse(state.running)
  assert.equal(state.stepInterval, 0.2)
  assert.equal(state.accumulator, 0)
end)

test("play and pause toggle running flag", function()
  local state = playback.create(0.2)
  playback.play(state)
  assert.isTrue(state.running)
  playback.pause(state)
  assert.isFalse(state.running)
end)

test("update does nothing when paused", function()
  local state = playback.create(0.1)
  local steps = 0

  playback.update(state, 0.3, function()
    steps = steps + 1
  end)

  assert.equal(steps, 0)
  assert.equal(state.accumulator, 0)
end)

test("update advances once when passing interval", function()
  local state = playback.create(0.1)
  local steps = 0
  playback.play(state)

  playback.update(state, 0.12, function()
    steps = steps + 1
  end)

  assert.equal(steps, 1)
  assert.isTrue(math.abs(state.accumulator - 0.02) < 1e-9)
end)

test("update advances multiple times for large dt", function()
  local state = playback.create(0.1)
  local steps = 0
  playback.play(state)

  playback.update(state, 0.35, function()
    steps = steps + 1
  end)

  assert.equal(steps, 3)
  assert.isTrue(math.abs(state.accumulator - 0.05) < 1e-9)
end)

test("stepForward advances and resets accumulator", function()
  local state = playback.create(0.1)
  local steps = 0
  state.accumulator = 0.09

  playback.stepForward(state, function()
    steps = steps + 1
  end)

  assert.equal(steps, 1)
  assert.equal(state.accumulator, 0)
end)

test("setStepInterval updates playback timing", function()
  local state = playback.create(0.2)
  playback.setStepInterval(state, 0.35)
  assert.equal(state.stepInterval, 0.35)
end)

test("restart pauses and resets accumulator", function()
  local state = playback.create(0.1)
  playback.play(state)
  state.accumulator = 0.09

  playback.restart(state)
  assert.isFalse(state.running)
  assert.equal(state.accumulator, 0)
end)
