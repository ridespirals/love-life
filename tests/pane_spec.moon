assert = require "tests.assert"
pane = require "src.ui.pane"
specHelper = require "tests.spec_helper"
test = specHelper.test
withLoveGraphicsMock = specHelper.withLoveGraphicsMock

config =
  statusBarHeight: 28
  paneWidth: 360
  paneHeight: 120
  paneScreenMargin: 8

anchor = x: 50, y: 480, w: 90, h: 16

test "create starts closed", ->
  state = pane.create!
  assert.equal state.openId, nil
  assert.equal pane.isOpen(state), false
  assert.equal pane.capturesInput(state), false

test "open and close pane", ->
  state = pane.create!
  pane.open state, "rule", anchor
  assert.equal pane.getOpenId(state), "rule"
  assert.equal pane.isOpen(state), true
  pane.close state
  assert.equal pane.getOpenId(state), nil

test "toggle opens and closes same pane", ->
  state = pane.create!
  pane.toggle state, "theme", anchor
  assert.equal pane.getOpenId(state), "theme"
  pane.toggle state, "theme", anchor
  assert.equal pane.getOpenId(state), nil

test "toggle switches between panes", ->
  state = pane.create!
  pane.toggle state, "rule", anchor
  pane.toggle state, "settings", anchor
  assert.equal pane.getOpenId(state), "settings"

test "getHeight is zero when closed and at least min height when open", ->
  state = pane.create!
  assert.equal pane.getHeight(config, state), 0
  pane.open state, "pattern", anchor
  assert.equal pane.getHeight(config, state), 120

test "hitTestClose detects close button when pane open", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    state = pane.create!
    pane.open state, "rule", anchor
    closeBtn = pane.getCloseButton config, state
    assert.isTrue closeBtn ~= nil
    assert.equal pane.hitTestClose(config, state, closeBtn.x + 1, closeBtn.y + 1), true
    assert.equal pane.hitTestClose(config, state, 0, 0), nil

test "ignores unknown pane ids", ->
  state = pane.create!
  pane.open state, "not_a_pane", anchor
  assert.equal pane.getOpenId(state), nil

test "docks pane left-aligned to anchor when it fits on screen", ->
  withLoveGraphicsMock { width: 800, height: 508 }, ->
    state = pane.create!
    pane.open state, "pattern", anchor
    rect = pane.getRect config, state
    assert.equal rect.x, anchor.x
    assert.equal rect.y, anchor.y - rect.h

test "hitTestPane detects inside pane rect", ->
  withLoveGraphicsMock { width: 800, height: 508 }, ->
    state = pane.create!
    pane.open state, "rule", anchor
    rect = pane.getRect config, state
    assert.equal pane.hitTestPane(config, state, rect.x + 1, rect.y + 1), true
    assert.equal pane.hitTestPane(config, state, 0, 0), nil

test "aligns pane right edge to anchor when left align overflows", ->
  withLoveGraphicsMock { width: 500, height: 508 }, ->
    state = pane.create!
    rightAnchor = x: 400, y: 480, w: 80, h: 16
    pane.open state, "rule", rightAnchor
    rect = pane.getRect config, state
    assert.equal rect.x, rightAnchor.x + rightAnchor.w - rect.w
    assert.equal rect.x + rect.w, rightAnchor.x + rightAnchor.w
