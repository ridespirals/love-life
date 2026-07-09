local assert = require("tests.assert")
local pane = require("src.ui.pane")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local withLoveGraphicsMock = specHelper.withLoveGraphicsMock

local config = {
  statusBarHeight = 28,
  paneWidth = 360,
  paneHeight = 120,
  paneScreenMargin = 8,
}

local anchor = { x = 50, y = 480, w = 90, h = 16 }

test("create starts closed", function()
  local state = pane.create()
  assert.equal(state.openId, nil)
  assert.equal(pane.isOpen(state), false)
  assert.equal(pane.capturesInput(state), false)
end)

test("open and close pane", function()
  local state = pane.create()
  pane.open(state, "rule", anchor)
  assert.equal(pane.getOpenId(state), "rule")
  assert.equal(pane.isOpen(state), true)
  pane.close(state)
  assert.equal(pane.getOpenId(state), nil)
end)

test("toggle opens and closes same pane", function()
  local state = pane.create()
  pane.toggle(state, "theme", anchor)
  assert.equal(pane.getOpenId(state), "theme")
  pane.toggle(state, "theme", anchor)
  assert.equal(pane.getOpenId(state), nil)
end)

test("toggle switches between panes", function()
  local state = pane.create()
  pane.toggle(state, "rule", anchor)
  pane.toggle(state, "settings", anchor)
  assert.equal(pane.getOpenId(state), "settings")
end)

test("getHeight is zero when closed and at least min height when open", function()
  local state = pane.create()
  assert.equal(pane.getHeight(config, state), 0)
  pane.open(state, "pattern", anchor)
  assert.equal(pane.getHeight(config, state), 120)
end)

test("hitTestClose detects close button when pane open", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local state = pane.create()
    pane.open(state, "rule", anchor)
    local close = pane.getCloseButton(config, state)
    assert.isTrue(close ~= nil)
    assert.equal(pane.hitTestClose(config, state, close.x + 1, close.y + 1), true)
    assert.equal(pane.hitTestClose(config, state, 0, 0), nil)
  end)
end)

test("ignores unknown pane ids", function()
  local state = pane.create()
  pane.open(state, "not_a_pane", anchor)
  assert.equal(pane.getOpenId(state), nil)
end)

test("docks pane left-aligned to anchor when it fits on screen", function()
  withLoveGraphicsMock({ width = 800, height = 508 }, function()
    local state = pane.create()
    pane.open(state, "pattern", anchor)
    local rect = pane.getRect(config, state)
    assert.equal(rect.x, anchor.x)
    assert.equal(rect.y, anchor.y - rect.h)
  end)
end)

test("hitTestPane detects inside pane rect", function()
  withLoveGraphicsMock({ width = 800, height = 508 }, function()
    local state = pane.create()
    pane.open(state, "rule", anchor)
    local rect = pane.getRect(config, state)
    assert.equal(pane.hitTestPane(config, state, rect.x + 1, rect.y + 1), true)
    assert.equal(pane.hitTestPane(config, state, 0, 0), nil)
  end)
end)

test("aligns pane right edge to anchor when left align overflows", function()
  withLoveGraphicsMock({ width = 500, height = 508 }, function()
    local state = pane.create()
    local rightAnchor = { x = 400, y = 480, w = 80, h = 16 }
    pane.open(state, "rule", rightAnchor)
    local rect = pane.getRect(config, state)
    assert.equal(rect.x, rightAnchor.x + rightAnchor.w - rect.w)
    assert.equal(rect.x + rect.w, rightAnchor.x + rightAnchor.w)
  end)
end)
