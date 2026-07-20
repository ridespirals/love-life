local assert = require("tests.assert")
local camera = require("src.camera")
local layout = require("src.layout")
local test = require("tests.spec_helper").test

local function makeConfig(overrides)
  local config = {
    rows = 40,
    cols = 60,
    baseVisualTile = 12,
    tileSize = 12,
    statusBarHeight = 28,
    cameraDefaultZoom = 1,
    cameraZoomMin = 0.05,
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

test("reset centers on board in cell units", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 60, 40)
  assert.equal(cam.x, 30)
  assert.equal(cam.y, 20)
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
    config.baseVisualTile,
    config.statusBarHeight
  )
  local got = camera.computeLayout(cam, config, viewW, viewH)

  assert.equal(got.offsetX, expected.offsetX)
  assert.equal(got.offsetY, expected.offsetY)
  assert.equal(got.tileSize, expected.tileSize)
  assert.equal(got.boardWidth, expected.boardWidth)
  assert.equal(got.boardHeight, expected.boardHeight)
end)

test("visualTileSize snaps to integer pixels", function()
  local config = makeConfig({ baseVisualTile = 24 })
  local cam = camera.create(config)
  cam.zoom = 1.25
  assert.equal(camera.visualTileSize(cam, config), 30)
  cam.zoom = 0.2
  assert.equal(camera.visualTileSize(cam, config), 5)
end)

test("worldToScreen and screenToWorld round-trip", function()
  local config = makeConfig()
  local cam = camera.create(config)
  camera.reset(cam, 60, 40)
  camera.pan(cam, 2, -1)
  camera.zoomBy(cam, 1.25, cam.x, cam.y)

  local viewW, viewH = 800, 572
  local sx, sy = camera.worldToScreen(cam, 10, 8, viewW, viewH, config)
  local wx, wy = camera.screenToWorld(cam, sx, sy, viewW, viewH, config)
  assert.isTrue(math.abs(wx - 10) < 1e-9)
  assert.isTrue(math.abs(wy - 8) < 1e-9)
end)

test("pan accumulates in cell units", function()
  local cam = camera.create(makeConfig())
  camera.reset(cam, 100, 100)
  camera.pan(cam, 10, -5)
  camera.pan(cam, 5, 2)
  assert.equal(cam.x, 65)
  assert.equal(cam.y, 47)
end)

test("panScreen divides by visual tile size", function()
  local config = makeConfig({ baseVisualTile = 10 })
  local cam = camera.create(config)
  camera.reset(cam, 100, 100)
  cam.zoom = 2
  camera.panScreen(cam, 20, 10, config)
  assert.equal(cam.x, 49)
  assert.equal(cam.y, 49.5)
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

test("clampToBoard prevents panning past edges", function()
  local config = makeConfig({ rows = 40, cols = 60, baseVisualTile = 12 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  local viewW, viewH = 240, 120
  cam.x = -100
  cam.y = -100
  camera.clampToBoard(cam, config, viewW, viewH)
  local halfW = (viewW / camera.visualTileSize(cam, config)) / 2
  local halfH = (viewH / camera.visualTileSize(cam, config)) / 2
  assert.isTrue(cam.x >= halfW - 1e-9)
  assert.isTrue(cam.y >= halfH - 1e-9)
  assert.isTrue(cam.x <= config.cols - halfW + 1e-9)
  assert.isTrue(cam.y <= config.rows - halfH + 1e-9)
end)

test("clampToBoard raises zoom so board covers viewport", function()
  local config = makeConfig({ rows = 10, cols = 10, baseVisualTile = 10 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  cam.zoom = 0.01
  camera.clampToBoard(cam, config, 400, 300)
  local cover = camera.coverZoom(config, 400, 300)
  assert.isTrue(cam.zoom + 1e-9 >= cover)
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
  local config = makeConfig({ rows = 100, cols = 200 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  local viewW, viewH = 400, 300
  local anchorX, anchorY = 20, 10
  local sx, sy = camera.worldToScreen(cam, anchorX, anchorY, viewW, viewH, config)

  camera.zoomBy(cam, 2, anchorX, anchorY, config, viewW, viewH)
  local sx2, sy2 = camera.worldToScreen(cam, anchorX, anchorY, viewW, viewH, config)
  assert.isTrue(math.abs(sx2 - sx) <= 1)
  assert.isTrue(math.abs(sy2 - sy) <= 1)
end)

test("computeLayout snaps tile size with zoom", function()
  local config = makeConfig({ baseVisualTile = 10, tileSize = 10, rows = 4, cols = 5 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  cam.zoom = 2

  local got = camera.computeLayout(cam, config, 400, 300)
  assert.equal(got.tileSize, 20)
  assert.equal(got.baseTileSize, 10)
  assert.equal(got.boardWidth, 100)
  assert.equal(got.boardHeight, 80)
end)

test("visibleCellRange returns cells intersecting the view", function()
  local config = makeConfig({ rows = 20, cols = 20, baseVisualTile = 10 })
  local cam = camera.create(config)
  camera.resetToBoard(cam, config)
  local layoutTable = camera.computeLayout(cam, config, 50, 50)
  local rowStart, rowEnd, colStart, colEnd = camera.visibleCellRange(layoutTable, 50, 50)
  assert.isTrue(rowStart >= 1)
  assert.isTrue(colStart >= 1)
  assert.isTrue(rowEnd <= 20)
  assert.isTrue(colEnd <= 20)
  assert.isTrue(rowEnd - rowStart < 20)
  assert.isTrue(colEnd - colStart < 20)
end)
