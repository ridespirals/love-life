function love.conf(t)
  -- Window sizing hints only (must be inlined: dofile/require cannot read inside
  -- a fused .love/.app; see src/config.lua for runtime settings).
  -- Viewport is intentionally smaller than the 512×512 world — camera shows a
  -- centered crop at baseVisualTile density.
  local viewRows = 40
  local viewCols = 60
  local tileSize = 24
  local statusBarHeight = 28
  local margin = 40
  local boardWidth = viewCols * tileSize
  local boardHeight = viewRows * tileSize

  t.window.title = "Love Life"
  t.window.width = boardWidth + margin * 2
  t.window.height = boardHeight + statusBarHeight + margin * 2
  t.window.resizable = true
  t.window.minwidth = 320
  t.window.minheight = 240
  t.window.vsync = 1

  t.modules.joystick = false
  t.modules.physics = false
end
