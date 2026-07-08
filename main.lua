local config = require("src.config")
local themes = require("src.themes")
local rules = require("src.rules")
local grid = require("src.grid")
local renderer = require("src.renderer")

local world
local theme
local activeRules

function love.load()
  world = grid.create(config.rows, config.cols)
  activeRules = rules.get(config.activeRule)
  grid.seedGlider(world)
  grid.computeNext(world, activeRules)
  theme = themes.get(config.activeTheme)
end

function love.draw()
  love.graphics.clear(theme.background[1], theme.background[2], theme.background[3], 1)
  renderer.draw(world, theme, config)
end
