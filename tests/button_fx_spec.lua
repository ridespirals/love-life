local assert = require("tests.assert")
local buttonFx = require("src.ui.button_fx")
local test = require("tests.spec_helper").test

local config = {
  buttonFxEnabled = true,
  buttonFxDurationSec = 0.4,
  buttonFxTrailCount = 3,
  buttonFxTrailSpacingSec = 0.05,
  buttonFxExpandPx = 10,
}

local rect = { x = 100, y = 200, w = 60, h = 20 }

test("create starts idle", function()
  local state = buttonFx.create(config)
  assert.isTrue(buttonFx.isIdle(state))
  assert.isFalse(buttonFx.isAnimating(state))
  assert.equal(state.targetId, nil)
end)

test("trigger enters active phase and stores targetId", function()
  local state = buttonFx.create(config)
  assert.isTrue(buttonFx.trigger(state, "play"))
  assert.isTrue(buttonFx.isAnimating(state))
  assert.equal(state.targetId, "play")
  assert.equal(buttonFx.progress(state), 0)
end)

test("disabled trigger is a no-op", function()
  local state = buttonFx.create({ buttonFxEnabled = false })
  assert.isFalse(buttonFx.trigger(state, "pause"))
  assert.isTrue(buttonFx.isIdle(state))
end)

test("update completes after duration plus trail lag", function()
  local state = buttonFx.create(config)
  buttonFx.trigger(state, "pause")

  assert.equal(buttonFx.update(state, 0.2), nil)
  assert.isTrue(buttonFx.isAnimating(state))

  -- total = 0.4 + 3 * 0.05 = 0.55
  assert.equal(buttonFx.update(state, 0.4), "done")
  assert.isTrue(buttonFx.isIdle(state))
  assert.equal(state.targetId, nil)
end)

test("trailFrames expands outward from rect", function()
  local state = buttonFx.create(config)
  buttonFx.trigger(state, "play")
  buttonFx.update(state, 0.1)

  local frames = buttonFx.trailFrames(state, rect)
  assert.isTrue(#frames >= 1)

  local lead = frames[1]
  assert.equal(lead.index, 0)
  assert.isTrue(lead.w > rect.w)
  assert.isTrue(lead.h > rect.h)
  assert.isTrue(lead.x < rect.x)
  assert.isTrue(lead.y < rect.y)
  assert.isTrue(lead.alpha > 0)
  assert.isTrue(lead.alpha <= 1)
end)

test("trailFrames includes delayed copies", function()
  local state = buttonFx.create({
    buttonFxEnabled = true,
    buttonFxDurationSec = 0.4,
    buttonFxTrailCount = 2,
    buttonFxTrailSpacingSec = 0.05,
    buttonFxExpandPx = 10,
  })
  buttonFx.trigger(state, "play")
  buttonFx.update(state, 0.12)

  local frames = buttonFx.trailFrames(state, rect)
  assert.equal(#frames, 3)

  -- Leading trail (index 0) should be larger / further expanded than later trails.
  assert.isTrue(frames[1].w >= frames[2].w)
  assert.isTrue(frames[2].w >= frames[3].w)
  assert.isTrue(frames[1].alpha >= frames[2].alpha)
end)

test("trailFrames empty while idle", function()
  local state = buttonFx.create(config)
  assert.equal(#buttonFx.trailFrames(state, rect), 0)
end)

test("cancel returns to idle", function()
  local state = buttonFx.create(config)
  buttonFx.trigger(state, "play")
  buttonFx.cancel(state)
  assert.isTrue(buttonFx.isIdle(state))
  assert.equal(state.targetId, nil)
end)

test("retriggers restart elapsed", function()
  local state = buttonFx.create(config)
  buttonFx.trigger(state, "play")
  buttonFx.update(state, 0.2)
  assert.isTrue(buttonFx.progress(state) > 0)

  buttonFx.trigger(state, "pause")
  assert.equal(state.targetId, "pause")
  assert.equal(buttonFx.progress(state), 0)
end)
