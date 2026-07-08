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
local generation = 0
local fastMode = false
local FAST_STEP_INTERVAL = 0.05

local function advanceGeneration()
  grid.step(world, activeRules)
  generation = generation + 1
end

local function stepForward()
  playback.stepForward(playbackState, advanceGeneration)
end

local function restartWorld()
  patterns.apply(world, config.defaultPattern)
  grid.computeNext(world, activeRules)
  playback.restart(playbackState)
  generation = 0
end

local function applyStepInterval()
  local stepInterval = config.stepInterval
  if fastMode then
    stepInterval = FAST_STEP_INTERVAL
  end
  playback.setStepInterval(playbackState, stepInterval)
end

local function setFastMode(enabled)
  fastMode = enabled
  applyStepInterval()
end

function love.load()
  world = grid.create(config.rows, config.cols)
  activeRules = rules.get(config.activeRule)
  patterns.apply(world, config.defaultPattern)
  grid.computeNext(world, activeRules)
  theme = themes.get(config.activeTheme)
  playbackState = playback.create(config.stepInterval)
  fastMode = false
  generation = 0
end

function love.update(dt)
  playback.update(playbackState, dt, advanceGeneration)
end

function love.draw()
  love.graphics.clear(theme.background[1], theme.background[2], theme.background[3], 1)
  renderer.draw(world, theme, config)
  statusbar.draw(world, theme, config, activeRules, generation, fastMode)
end

function love.keypressed(key)
  if key == "space" then
    playback.toggle(playbackState)
  elseif key == "p" then
    playback.pause(playbackState)
  elseif key == "s" then
    playback.play(playbackState)
  elseif key == "n" or key == "right" then
    stepForward()
  elseif key == "r" then
    restartWorld()
  elseif key == "f" then
    setFastMode(true)
  elseif key == "q" then
    love.event.quit()
  end
end

function love.keyreleased(key)
  if key == "f" then
    setFastMode(false)
  end
end

function love.mousepressed(x, y, button)
  if button ~= 1 then
    return
  end

  local hit = statusbar.hitTestButton(config, x, y)
  if hit == "play" then
    playback.play(playbackState)
  elseif hit == "pause" then
    playback.pause(playbackState)
  elseif hit == "step" then
    stepForward()
  elseif hit == "restart" then
    restartWorld()
  end
end
