-- World↔screen camera: pan/zoom over a fixed dense board.
-- World units are cells (board size = cols × rows). Screen tile size is an
-- integer visualTile = max(1, round(baseVisualTile * zoom)).
-- Pan/zoom are clamped so the board always covers the viewport (no void).
local M = {}

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

function M.create(config)
  config = config or {}
  return {
    x = 0,
    y = 0,
    zoom = config.cameraDefaultZoom or 1,
    zoomMin = config.cameraZoomMin or 0.05,
    zoomMax = config.cameraZoomMax or 8,
    zoomStep = config.cameraZoomStep or 1.25,
    defaultZoom = config.cameraDefaultZoom or 1,
  }
end

function M.baseVisualTile(config)
  config = config or {}
  return config.baseVisualTile or config.tileSize or 24
end

-- Integer screen pixels per cell (snapped).
function M.visualTileSize(camera, config)
  local base = M.baseVisualTile(config)
  local zoom = camera and camera.zoom or 1
  return math.max(1, math.floor(base * zoom + 0.5))
end

-- Board size in cell units.
function M.boardSize(config)
  return config.cols or 1, config.rows or 1
end

-- Center on the board at default zoom. boardWidth/Height are cell units.
function M.reset(camera, boardWidth, boardHeight)
  camera.x = boardWidth / 2
  camera.y = boardHeight / 2
  camera.zoom = camera.defaultZoom
end

function M.resetToBoard(camera, config)
  local boardWidth, boardHeight = M.boardSize(config)
  M.reset(camera, boardWidth, boardHeight)
end

-- Minimum zoom so the board still covers the entire viewport (no letterbox void).
function M.coverZoom(config, viewW, viewH)
  local base = M.baseVisualTile(config)
  local cols, rows = M.boardSize(config)
  if cols < 1 then
    cols = 1
  end
  if rows < 1 then
    rows = 1
  end
  return math.max(viewW / (cols * base), viewH / (rows * base))
end

function M.zoomMinForView(camera, config, viewW, viewH)
  local cover = M.coverZoom(config, viewW, viewH)
  return math.max(camera.zoomMin or 0.05, cover)
end

-- Keep pan/zoom so the viewport stays over the board.
function M.clampToBoard(camera, config, viewW, viewH)
  local minZoom = M.zoomMinForView(camera, config, viewW, viewH)
  local maxZoom = camera.zoomMax or 8
  camera.zoom = clamp(camera.zoom, minZoom, maxZoom)

  local vt = M.visualTileSize(camera, config)
  local cols, rows = M.boardSize(config)
  local viewCellsW = viewW / vt
  local viewCellsH = viewH / vt

  local minX = viewCellsW / 2
  local maxX = cols - viewCellsW / 2
  if minX > maxX then
    camera.x = cols / 2
  else
    camera.x = clamp(camera.x, minX, maxX)
  end

  local minY = viewCellsH / 2
  local maxY = rows - viewCellsH / 2
  if minY > maxY then
    camera.y = rows / 2
  else
    camera.y = clamp(camera.y, minY, maxY)
  end
end

function M.origin(camera, viewW, viewH, config)
  local vt = M.visualTileSize(camera, config)
  return math.floor(viewW / 2 - camera.x * vt), math.floor(viewH / 2 - camera.y * vt)
end

function M.worldToScreen(camera, worldX, worldY, viewW, viewH, config)
  local ox, oy = M.origin(camera, viewW, viewH, config)
  local vt = M.visualTileSize(camera, config)
  return ox + worldX * vt, oy + worldY * vt
end

function M.screenToWorld(camera, screenX, screenY, viewW, viewH, config)
  local ox, oy = M.origin(camera, viewW, viewH, config)
  local vt = M.visualTileSize(camera, config)
  return (screenX - ox) / vt, (screenY - oy) / vt
end

-- Move the camera in cell units (positive x moves view right content left).
function M.pan(camera, dxWorld, dyWorld)
  camera.x = camera.x + dxWorld
  camera.y = camera.y + dyWorld
end

-- Pan by screen-pixel drag (positive dxScreen = drag right = content follows finger).
function M.panScreen(camera, dxScreen, dyScreen, config)
  local vt = M.visualTileSize(camera, config)
  camera.x = camera.x - dxScreen / vt
  camera.y = camera.y - dyScreen / vt
end

-- Zoom by factor around a world-space (cell) anchor. Optional view size enables cover clamp.
function M.zoomBy(camera, factor, anchorWorldX, anchorWorldY, config, viewW, viewH)
  local oldZoom = camera.zoom
  local minZoom = camera.zoomMin or 0.05
  local maxZoom = camera.zoomMax or 8
  if config and viewW and viewH then
    minZoom = M.zoomMinForView(camera, config, viewW, viewH)
  end
  local newZoom = clamp(oldZoom * factor, minZoom, maxZoom)
  if newZoom == oldZoom then
    if config and viewW and viewH then
      M.clampToBoard(camera, config, viewW, viewH)
    end
    return false
  end

  camera.x = anchorWorldX + (camera.x - anchorWorldX) * (oldZoom / newZoom)
  camera.y = anchorWorldY + (camera.y - anchorWorldY) * (oldZoom / newZoom)
  camera.zoom = newZoom
  if config and viewW and viewH then
    M.clampToBoard(camera, config, viewW, viewH)
  end
  return true
end

function M.zoomAtViewCenter(camera, factor, config, viewW, viewH)
  return M.zoomBy(camera, factor, camera.x, camera.y, config, viewW, viewH)
end

-- Inclusive visible cell indices for viewport culling.
function M.visibleCellRange(layout, viewW, viewH)
  local tileSize = layout.tileSize
  local cols = layout.cols
  local rows = layout.rows
  if not tileSize or tileSize <= 0 then
    return 1, rows, 1, cols
  end

  local colStart = math.max(1, math.floor((0 - layout.offsetX) / tileSize) + 1)
  local colEnd = math.min(cols, math.ceil((viewW - layout.offsetX) / tileSize))
  local rowStart = math.max(1, math.floor((0 - layout.offsetY) / tileSize) + 1)
  local rowEnd = math.min(rows, math.ceil((viewH - layout.offsetY) / tileSize))
  if colStart > colEnd or rowStart > rowEnd then
    return 1, 0, 1, 0
  end
  return rowStart, rowEnd, colStart, colEnd
end

-- Layout table compatible with renderer/board (screen-space tile size is snapped).
function M.computeLayout(camera, config, viewW, viewH)
  local rows = config.rows
  local cols = config.cols
  local zoom = camera.zoom
  local screenTile = M.visualTileSize(camera, config)
  local baseTile = M.baseVisualTile(config)
  local ox, oy = M.origin(camera, viewW, viewH, config)

  return {
    offsetX = ox,
    offsetY = oy,
    boardWidth = cols * screenTile,
    boardHeight = rows * screenTile,
    tileSize = screenTile,
    baseTileSize = baseTile,
    rows = rows,
    cols = cols,
    zoom = zoom,
  }
end

return M
