-- World↔screen camera: pan/zoom independent of simulation grid size.
-- World origin is the top-left of cell (1,1) in board pixel space (cols*tileSize).
-- At reset (centered, zoom=1) screen offsets match layout.computeBoardLayout.
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
    zoomMin = config.cameraZoomMin or 0.25,
    zoomMax = config.cameraZoomMax or 4,
    zoomStep = config.cameraZoomStep or 1.25,
    defaultZoom = config.cameraDefaultZoom or 1,
  }
end

-- Center on the board at default zoom. boardWidth/Height are world pixels.
function M.reset(camera, boardWidth, boardHeight)
  camera.x = boardWidth / 2
  camera.y = boardHeight / 2
  camera.zoom = camera.defaultZoom
end

function M.boardSize(config)
  local tileSize = config.tileSize or 1
  return (config.cols or 1) * tileSize, (config.rows or 1) * tileSize
end

function M.resetToBoard(camera, config)
  local boardWidth, boardHeight = M.boardSize(config)
  M.reset(camera, boardWidth, boardHeight)
end

-- Screen origin of world (0,0): matches letterbox floor math at zoom=1 centered.
function M.origin(camera, viewW, viewH)
  local zoom = camera.zoom
  return math.floor(viewW / 2 - camera.x * zoom), math.floor(viewH / 2 - camera.y * zoom)
end

function M.worldToScreen(camera, worldX, worldY, viewW, viewH)
  local ox, oy = M.origin(camera, viewW, viewH)
  local zoom = camera.zoom
  return ox + worldX * zoom, oy + worldY * zoom
end

function M.screenToWorld(camera, screenX, screenY, viewW, viewH)
  local ox, oy = M.origin(camera, viewW, viewH)
  local zoom = camera.zoom
  return (screenX - ox) / zoom, (screenY - oy) / zoom
end

-- Move the camera in world-space pixels (positive x moves view right content left).
function M.pan(camera, dxWorld, dyWorld)
  camera.x = camera.x + dxWorld
  camera.y = camera.y + dyWorld
end

-- Pan by screen-pixel drag (positive dxScreen = drag right = content follows finger).
function M.panScreen(camera, dxScreen, dyScreen)
  camera.x = camera.x - dxScreen / camera.zoom
  camera.y = camera.y - dyScreen / camera.zoom
end

-- Zoom by factor around a world-space anchor (anchor stays fixed on screen).
function M.zoomBy(camera, factor, anchorWorldX, anchorWorldY)
  local oldZoom = camera.zoom
  local newZoom = clamp(oldZoom * factor, camera.zoomMin, camera.zoomMax)
  if newZoom == oldZoom then
    return false
  end

  camera.x = anchorWorldX + (camera.x - anchorWorldX) * (oldZoom / newZoom)
  camera.y = anchorWorldY + (camera.y - anchorWorldY) * (oldZoom / newZoom)
  camera.zoom = newZoom
  return true
end

function M.zoomAtViewCenter(camera, factor)
  return M.zoomBy(camera, factor, camera.x, camera.y)
end

-- Layout table compatible with renderer/board (screen-space tile size includes zoom).
function M.computeLayout(camera, config, viewW, viewH)
  local baseTile = config.tileSize
  local rows = config.rows
  local cols = config.cols
  local zoom = camera.zoom
  local screenTile = baseTile * zoom
  local ox, oy = M.origin(camera, viewW, viewH)

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
