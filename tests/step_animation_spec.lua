local assert = require("tests.assert")
local grid = require("src.grid")
local rules = require("src.rules")
local stepAnimation = require("src.step_animation")
local test = require("tests.spec_helper").test

local config = {
  stepAnimEnabled = true,
  stepAnimSec = 0.3,
}

local conway = rules.get("conway")

test("create starts idle", function()
  local state = stepAnimation.create(config)
  assert.isTrue(stepAnimation.isIdle(state))
  assert.isFalse(stepAnimation.isAnimating(state))
end)

test("begin enters morph", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)
  assert.isFalse(stepAnimation.isIdle(state))
  assert.equal(stepAnimation.getMorphT(state), 0)
end)

test("update advances morph to commit", function()
  local state = stepAnimation.create(config)
  stepAnimation.begin(state)

  assert.equal(stepAnimation.update(state, 0.1), nil)
  assert.isTrue(stepAnimation.getMorphT(state) > 0)

  assert.equal(stepAnimation.update(state, 0.25), "commit")
  assert.isTrue(stepAnimation.isIdle(state))
end)

test("disabled begin requests immediate commit", function()
  local state = stepAnimation.create({ stepAnimEnabled = false })
  assert.equal(stepAnimation.begin(state), "commit_immediate")
  assert.isTrue(stepAnimation.isIdle(state))
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

test("speedScale greater than 1 completes morph faster", function()
  local state = stepAnimation.create({
    stepAnimEnabled = true,
    stepAnimSec = 0.2,
  })
  stepAnimation.setSpeedScale(state, 4)
  stepAnimation.begin(state)

  assert.equal(stepAnimation.update(state, 0.06), "commit")
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

test("default morph duration when stepAnimSec omitted", function()
  local state = stepAnimation.create({ stepAnimEnabled = true })
  stepAnimation.begin(state)
  assert.equal(stepAnimation.update(state, 0.19), nil)
  assert.equal(stepAnimation.update(state, 0.02), "commit")
end)
