function love.conf(t)
  local config = dofile("src/config.lua")
  local margin = 40
  local boardWidth = config.cols * config.tileSize
  local boardHeight = config.rows * config.tileSize

  t.window.title = "Love Life"
  t.window.width = boardWidth + margin * 2
  t.window.height = boardHeight + config.statusBarHeight + margin * 2
  t.window.resizable = true
  t.window.minwidth = 320
  t.window.minheight = 240
  t.window.vsync = 1

  t.modules.joystick = false
  t.modules.physics = false
end
