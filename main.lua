local config = require("src.config")
local themes = require("src.themes")
local grid = require("src.grid")
local renderer = require("src.renderer")

local world
local theme

function love.load()
  world = grid.create(config.rows, config.cols)
  grid.seedGlider(world)
  grid.computeNext(world)
  theme = themes.get(config.activeTheme)
end

function love.draw()
  love.graphics.clear(theme.background[1], theme.background[2], theme.background[3], 1)
  renderer.draw(world, theme, config)
end
