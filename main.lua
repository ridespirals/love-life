local config = require("src.config")
local themes = require("src.themes")
local rules = require("src.rules")
local grid = require("src.grid")
local patterns = require("src.patterns")
local playback = require("src.playback")
local renderer = require("src.renderer")
local statusbar = require("src.ui.statusbar")

local world
local theme
local activeRules
local playbackState

function love.load()
  world = grid.create(config.rows, config.cols)
  activeRules = rules.get(config.activeRule)
  patterns.apply(world, config.defaultPattern)
  grid.computeNext(world, activeRules)
  theme = themes.get(config.activeTheme)
  playbackState = playback.create(config.stepInterval)
end

function love.update(dt)
  playback.update(playbackState, dt, function()
    grid.step(world, activeRules)
  end)
end

function love.draw()
  love.graphics.clear(theme.background[1], theme.background[2], theme.background[3], 1)
  renderer.draw(world, theme, config)
  statusbar.draw(world, theme, config, activeRules)
end

function love.keypressed(key)
  if key == "space" then
    playback.toggle(playbackState)
  elseif key == "p" then
    playback.pause(playbackState)
  elseif key == "s" then
    playback.play(playbackState)
  elseif key == "n" or key == "right" then
    playback.stepForward(playbackState, function()
      grid.step(world, activeRules)
    end)
  elseif key == "q" then
    love.event.quit()
  end
end
