local config = require("src.config")
local themes = require("src.themes")
local rules = require("src.rules")
local grid = require("src.grid")
local patterns = require("src.patterns")
local playback = require("src.playback")
local renderer = require("src.renderer")
local statusbar = require("src.ui.statusbar")
local layout = require("src.layout")
local stepAnimation = require("src.step_animation")

local world
local theme
local activeRule
local playbackState
local animState
local generation = 0
local fastMode = false
local FAST_STEP_INTERVAL = 0.05
local FAST_ANIM_SPEED_MULTIPLIER = 4

local function canRequestStep()
  return stepAnimation.isIdle(animState)
end

local function commitGeneration()
  grid.step(world, activeRule)
  grid.computeNext(world, activeRule)
  generation = generation + 1
end

local function requestStep()
  if not canRequestStep() then
    return
  end

  local result = stepAnimation.begin(animState)
  if result == "commit_immediate" then
    commitGeneration()
  end
end

local function stepForward()
  if not canRequestStep() then
    return
  end
  playback.stepForward(playbackState, requestStep)
end

local function applyStepInterval()
  local stepInterval = config.stepInterval
  if fastMode then
    stepInterval = FAST_STEP_INTERVAL
  end
  playback.setStepInterval(playbackState, stepInterval)
end

local function applyAnimSpeed()
  local scale = 1
  if fastMode then
    scale = FAST_ANIM_SPEED_MULTIPLIER
  end
  stepAnimation.setSpeedScale(animState, scale)
end

local function setFastMode(enabled)
  fastMode = enabled
  applyStepInterval()
  applyAnimSpeed()
end

local function resetSimulation(opts)
  stepAnimation.cancel(animState)

  if opts and opts.resize then
    local windowWidth, windowHeight = love.graphics.getDimensions()
    config.rows, config.cols = layout.computeGridSize(
      windowWidth,
      windowHeight,
      config.tileSize,
      config.statusBarHeight
    )
    world = grid.create(config.rows, config.cols)
  end

  patterns.apply(world, config.defaultPattern)
  grid.computeNext(world, activeRule)
  playback.restart(playbackState)
  generation = 0
end

local function restartWorld()
  resetSimulation()
end

local function rebuildWorldForWindow()
  resetSimulation({ resize = true })
end

local function toggleFullscreen()
  local fullscreen, fstype = love.window.getFullscreen()
  love.window.setFullscreen(not fullscreen, fstype or "desktop")
end

function love.load()
  activeRule = rules.get(config.activeRule)
  theme = themes.get(config.activeTheme)
  playbackState = playback.create(config.stepInterval)
  animState = stepAnimation.create(config)
  fastMode = false
  applyAnimSpeed()
  rebuildWorldForWindow()
end

function love.resize()
  rebuildWorldForWindow()
end

function love.update(dt)
  local commit = stepAnimation.update(animState, dt)
  if commit == "commit" then
    commitGeneration()
  end

  if stepAnimation.isIdle(animState) then
    playback.update(playbackState, dt, requestStep)
  end
end

function love.draw()
  love.graphics.clear(theme.background[1], theme.background[2], theme.background[3], 1)
  renderer.draw(world, theme, config, animState)
  statusbar.draw(world, theme, config, activeRule, generation, fastMode)
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
  elseif key == "f11" then
    toggleFullscreen()
  elseif key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
    toggleFullscreen()
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

  local hit = statusbar.hitTestButton(config, x, y, fastMode)
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
