function love.conf(t)
  -- Window sizing hints only (must be inlined: dofile/require cannot read inside
  -- a fused .love/.app; see src/config.lua for runtime settings).
  local rows = 40
  local cols = 60
  local tileSize = 12
  local statusBarHeight = 28
  local margin = 40
  local boardWidth = cols * tileSize
  local boardHeight = rows * tileSize

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
