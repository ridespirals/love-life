local assert = require("tests.assert")
local grid = require("src.grid")
local rules = require("src.rules")
local stepAnimation = require("src.step_animation")
local test = require("tests.spec_helper").test

local config = {
  stepAnimEnabled = true,
  tileSize = 24,
  stepAnimPreviewSec = 0.1,
  stepAnimCommitSec = 0.2,
}

local conway = rules.get("conway")

test("create starts idle", function()
  local state = stepAnimation.create(config)
  assert.isTrue(stepAnimation.isIdle(state))
  assert.isFalse(stepAnimation.isAnimating(state))
end)

test("begin enters preview phase", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)
  assert.isFalse(stepAnimation.isIdle(state))
  local phase, t = stepAnimation.getPhaseT(state)
  assert.equal(phase, "preview")
  assert.equal(t, 0)
end)

test("update advances preview to commit to grid commit", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)

  assert.equal(stepAnimation.update(state, 0.05), nil)
  local phase = stepAnimation.getPhaseT(state)
  assert.equal(phase, "preview")

  assert.equal(stepAnimation.update(state, 0.06), nil)
  phase = stepAnimation.getPhaseT(state)
  assert.equal(phase, "commit")

  assert.equal(stepAnimation.update(state, 0.1), nil)
  assert.equal(stepAnimation.update(state, 0.15), "commit")
  assert.isTrue(stepAnimation.isIdle(state))
end)

test("disabled begin requests immediate commit", function()
  local state = stepAnimation.create({ stepAnimEnabled = false, tileSize = 24 })
  assert.equal(stepAnimation.begin(state), "commit_immediate")
  assert.isTrue(stepAnimation.isIdle(state))
end)

test("effectiveEnabled is false when tile size is below minimum", function()
  assert.isFalse(stepAnimation.effectiveEnabled({
    stepAnimEnabled = true,
    tileSize = 5,
    stepAnimMinTileSize = 6,
  }))
  assert.isTrue(stepAnimation.effectiveEnabled({
    stepAnimEnabled = true,
    tileSize = 6,
    stepAnimMinTileSize = 6,
  }))
end)

test("effectiveEnabled uses visual tile when provided", function()
  assert.isFalse(stepAnimation.effectiveEnabled({
    stepAnimEnabled = true,
    tileSize = 24,
    stepAnimMinTileSize = 6,
  }, 4))
  assert.isTrue(stepAnimation.effectiveEnabled({
    stepAnimEnabled = true,
    tileSize = 4,
    stepAnimMinTileSize = 6,
  }, 12))
end)

test("create disables animation when tile size is below minimum", function()
  local state = stepAnimation.create({
    stepAnimEnabled = true,
    tileSize = 4,
    stepAnimMinTileSize = 6,
  })
  assert.isFalse(state.enabled)
  assert.equal(stepAnimation.begin(state), "commit_immediate")
end)

test("syncEnabled cancels in-flight animation when tile size drops below minimum", function()
  local state = stepAnimation.create({
    stepAnimEnabled = true,
    tileSize = 24,
    stepAnimPreviewSec = 0.1,
    stepAnimCommitSec = 0.2,
  })
  stepAnimation.begin(state)
  stepAnimation.syncEnabled(state, {
    stepAnimEnabled = true,
    tileSize = 4,
    stepAnimMinTileSize = 6,
  })
  assert.isTrue(stepAnimation.isIdle(state))
  assert.isFalse(state.enabled)
end)

test("begin while animating is ignored", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)
  assert.equal(stepAnimation.begin(state), nil)
end)

test("cancel returns to idle", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)
  stepAnimation.cancel(state)
  assert.isTrue(stepAnimation.isIdle(state))
end)

test("getCellChange detects birth and death", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 2, 2, true)
  grid.computeNext(world, conway)

  assert.equal(stepAnimation.getCellChange(world, 2, 2), "death")
  assert.equal(stepAnimation.getCellChange(world, 1, 2), "unchanged")
end)

test("speedScale greater than 1 completes phases faster", function()
  local state = stepAnimation.create({
    stepAnimEnabled = true,
    tileSize = 24,
    stepAnimPreviewSec = 0.1,
    stepAnimCommitSec = 0.1,
  })
  stepAnimation.setSpeedScale(state, 4)
  stepAnimation.begin(state)

  assert.equal(stepAnimation.update(state, 0.03), nil)
  assert.equal(stepAnimation.getPhaseT(state), "commit")

  assert.equal(stepAnimation.update(state, 0.03), "commit")
  assert.isTrue(stepAnimation.isIdle(state))
end)

test("getCellChange detects birth from three neighbors", function()
  local world = grid.create(3, 3)
  grid.setAlive(world, 1, 1, true)
  grid.setAlive(world, 1, 2, true)
  grid.setAlive(world, 2, 1, true)
  grid.computeNext(world, conway)
  assert.equal(stepAnimation.getCellChange(world, 2, 2), "birth")
end)

test("stepAnimSec splits into preview and commit when phases omitted", function()
  local state = stepAnimation.create({
    stepAnimEnabled = true,
    tileSize = 24,
    stepAnimSec = 0.3,
  })
  stepAnimation.begin(state)
  assert.equal(stepAnimation.update(state, 0.11), nil)
  assert.equal(stepAnimation.getPhaseT(state), "preview")
  assert.equal(stepAnimation.update(state, 0.02), nil)
  assert.equal(stepAnimation.getPhaseT(state), "commit")
  assert.equal(stepAnimation.update(state, 0.19), "commit")
end)
