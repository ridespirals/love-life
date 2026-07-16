local assert = require("tests.assert")
local camera = require("src.camera")
local layout = require("src.layout")
local test = require("tests.spec_helper").test

local function makeConfig(overrides)
  local config = {
    rows = 40,
    cols = 60,
    tileSize = 12,
    statusBarHeight = 28,
    cameraDefaultZoom = 1,
    cameraZoomMin = 0.25,
    cameraZoomMax = 4,
    cameraZoomStep = 1.25,
  }
  if overrides then
    for key, value in pairs(overrides) do
      config[key] = value
    end
  end
  return config
end

test("create starts at default zoom", function()
  local cam = camera.create(makeConfig())
  assert.equal(cam.zoom, 1)
end)

test("reset centers on board", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 720, 480)
  assert.equal(cam.x, 360)
  assert.equal(cam.y, 240)
  assert.equal(cam.zoom, 1)
end)

test("reset at zoom 1 matches computeBoardLayout offsets", function()
  local config = makeConfig()
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)

  local viewW, viewH = 800, 600 - config.statusBarHeight
  local expected = layout.computeBoardLayout(
    800,
    600,
    config.rows,
    config.cols,
    config.tileSize,
    config.statusBarHeight
  )
  local got = camera.computeLayout(cam, config, viewW, viewH)

  assert.equal(got.offsetX, expected.offsetX)
  assert.equal(got.offsetY, expected.offsetY)
  assert.equal(got.tileSize, expected.tileSize)
  assert.equal(got.boardWidth, expected.boardWidth)
  assert.equal(got.boardHeight, expected.boardHeight)
end)

test("worldToScreen and screenToWorld round-trip", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 720, 480)
  camera.pan(cam, 40, -20)
  camera.zoomBy(cam, 1.25, cam.x, cam.y)

  local viewW, viewH = 800, 572
  local sx, sy = camera.worldToScreen(cam, 120, 90, viewW, viewH)
  local wx, wy = camera.screenToWorld(cam, sx, sy, viewW, viewH)
  assert.isTrue(math.abs(wx - 120) < 1e-9)
  assert.isTrue(math.abs(wy - 90) < 1e-9)
end)

test("pan accumulates in world space", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 100, 100)
  camera.pan(cam, 10, -5)
  camera.pan(cam, 5, 2)
  assert.equal(cam.x, 65)
  assert.equal(cam.y, 47)
end)

test("panScreen divides by zoom", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 100, 100)
  cam.zoom = 2
  camera.panScreen(cam, 20, 10)
  assert.equal(cam.x, 40)
  assert.equal(cam.y, 45)
end)

test("zoomBy clamps to min and max", function()
  local cam = camera.create(makeConfig({
    cameraZoomMin = 0.5,
    cameraZoomMax = 2,
  }))
  camera.reset(cam, 100, 100)

  camera.zoomBy(cam, 0.1, cam.x, cam.y)
  assert.equal(cam.zoom, 0.5)

  camera.zoomBy(cam, 100, cam.x, cam.y)
  assert.equal(cam.zoom, 2)
end)

test("zoomAtViewCenter keeps camera center fixed", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 200, 100)
  local cx, cy = cam.x, cam.y
  camera.zoomAtViewCenter(cam, 1.25)
  assert.equal(cam.x, cx)
  assert.equal(cam.y, cy)
  assert.equal(cam.zoom, 1.25)
end)

test("zoomBy around anchor keeps anchor on screen", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 200, 100)
  local viewW, viewH = 400, 300
  local anchorX, anchorY = 20, 10
  local sx, sy = camera.worldToScreen(cam, anchorX, anchorY, viewW, viewH)

  camera.zoomBy(cam, 2, anchorX, anchorY)
  local sx2, sy2 = camera.worldToScreen(cam, anchorX, anchorY, viewW, viewH)
  -- floor in origin can introduce sub-pixel drift; stay within 1px
  assert.isTrue(math.abs(sx2 - sx) <= 1)
  assert.isTrue(math.abs(sy2 - sy) <= 1)
end)

test("computeLayout scales tile size with zoom", function()
  local config = makeConfig({ tileSize = 10, rows = 4, cols = 5 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  cam.zoom = 2

  local got = camera.computeLayout(cam, config, 400, 300)
  assert.equal(got.tileSize, 20)
  assert.equal(got.baseTileSize, 10)
  assert.equal(got.boardWidth, 100)
  assert.equal(got.boardHeight, 80)
end)
