config = require "src.config"
themes = require "src.themes"
rules = require "src.rules"
grid = require "src.grid"
patterns = require "src.patterns"
playback = require "src.playback"
renderer = require "src.renderer"
statusbar = require "src.ui.statusbar"
pane = require "src.ui.pane"
session = require "src.session"
rule_pane = require "src.ui.panes.rule_pane"
theme_pane = require "src.ui.panes.theme_pane"
layout = require "src.layout"
stepAnimation = require "src.step_animation"

world = nil
theme = nil
activeRule = nil
playbackState = nil
animState = nil
generation = 0
fastMode = false
fastKeyboard = false
fastPlayMouse = false
paneState = nil
sessionState = nil
FAST_STEP_INTERVAL = 0.05
FAST_ANIM_SPEED_MULTIPLIER = 4

syncDraftForPane = (id) ->
  if id == "rule"
    session.resetRuleDraft sessionState, activeRule
  elseif id == "theme"
    session.resetThemeDraft sessionState, theme, themes

applyRuleDraft = ->
  rule = rule_pane.apply sessionState
  return unless rule
  playback.pause playbackState
  stepAnimation.cancel animState
  activeRule = rule
  sessionState.appliedRuleId = rule.name
  grid.computeNext world, activeRule
  pane.close paneState

applyThemeDraft = ->
  nextTheme = theme_pane.apply sessionState
  return unless nextTheme
  theme = nextTheme
  sessionState.appliedThemeId = nextTheme.name
  pane.close paneState

togglePane = (id, anchor) ->
  syncDraftForPane id unless paneState.openId == id
  pane.toggle paneState, id, anchor

canRequestStep = ->
  stepAnimation.isIdle animState

commitGeneration = ->
  grid.step world, activeRule
  grid.computeNext world, activeRule
  generation += 1

requestStep = ->
  return unless canRequestStep!
  result = stepAnimation.begin animState
  commitGeneration! if result == "commit_immediate"

stepForward = ->
  return unless canRequestStep!
  playback.stepForward playbackState, requestStep

applyStepInterval = ->
  stepInterval = config.stepInterval
  stepInterval = FAST_STEP_INTERVAL if fastMode
  playback.setStepInterval playbackState, stepInterval

applyAnimSpeed = ->
  scale = if fastMode then FAST_ANIM_SPEED_MULTIPLIER else 1
  stepAnimation.setSpeedScale animState, scale

syncFastMode = ->
  fastMode = fastKeyboard or fastPlayMouse
  applyStepInterval!
  applyAnimSpeed!

resetSimulation = (opts) ->
  stepAnimation.cancel animState
  if opts and opts.resize
    windowWidth, windowHeight = love.graphics.getDimensions!
    config.rows, config.cols = layout.computeGridSize(
      windowWidth, windowHeight, config.tileSize, config.statusBarHeight
    )
    world = grid.create config.rows, config.cols
  patterns.apply world, config.defaultPattern
  grid.computeNext world, activeRule
  playback.restart playbackState
  generation = 0
  sessionState.appliedPatternId = config.defaultPattern

restartWorld = ->
  resetSimulation!

rebuildWorldForWindow = ->
  resetSimulation resize: true

toggleFullscreen = ->
  fullscreen, fstype = love.window.getFullscreen!
  love.window.setFullscreen not fullscreen, fstype or "desktop"

love.load = ->
  activeRule = rules.get config.activeRule
  theme = themes.get config.activeTheme
  playbackState = playback.create config.stepInterval
  animState = stepAnimation.create config
  sessionState = session.create {
    ruleId: config.activeRule
    themeId: config.activeTheme
    patternId: config.defaultPattern
  }
  paneState = pane.create!
  fastMode = false
  applyAnimSpeed!
  rebuildWorldForWindow!

love.resize = ->
  rebuildWorldForWindow!

love.update = (dt) ->
  commit = stepAnimation.update animState, dt
  commitGeneration! if commit == "commit"
  playback.update playbackState, dt, requestStep if stepAnimation.isIdle animState

love.draw = ->
  love.graphics.clear theme.background[1], theme.background[2], theme.background[3], 1
  renderer.draw world, theme, config, animState
  statusbar.draw world, theme, config, activeRule, generation, sessionState.appliedPatternId, fastMode, paneState
  pane.draw paneState, theme, config, sessionState
  if pane.isOpen paneState
    statusbar.drawOpenerLabel world, theme, config, activeRule, generation, sessionState.appliedPatternId, fastMode, paneState.anchor

love.keypressed = (key) ->
  if key == "escape"
    if pane.isOpen paneState
      pane.close paneState
      return
  if pane.isOpen paneState
    return if pane.keypressed paneState, sessionState, key
    return unless key == "q"
  if key == "space"
    playback.toggle playbackState
  elseif key == "p"
    playback.pause playbackState
  elseif key == "s"
    playback.play playbackState
  elseif key == "n" or key == "right"
    stepForward!
  elseif key == "r"
    restartWorld!
  elseif key == "f"
    fastKeyboard = true
    syncFastMode!
  elseif key == "f11"
    toggleFullscreen!
  elseif key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
    toggleFullscreen!
  elseif key == "q"
    love.event.quit!

love.keyreleased = (key) ->
  if key == "f"
    fastKeyboard = false
    syncFastMode!

love.textinput = (text) ->
  pane.textinput paneState, sessionState, text if pane.isOpen paneState

love.mousepressed = (x, y, button) ->
  return unless button == 1
  if pane.hitTestClose config, paneState, x, y
    pane.close paneState
    return
  chipPane, chipAnchor = statusbar.hitTestChip(
    world, theme, config, activeRule, generation, sessionState.appliedPatternId, x, y
  )
  if chipPane
    togglePane chipPane, chipAnchor
    return
  hit = statusbar.hitTestButton config, x, y, fastMode
  if hit == "settings"
    togglePane "settings", statusbar.getButton(config, fastMode, "settings")
    return
  if pane.hitTestPane config, paneState, x, y
    action = pane.mousepressed paneState, sessionState, x, y, theme, config
    if action == "apply_rule"
      applyRuleDraft!
    elseif action == "apply_theme"
      applyThemeDraft!
    return
  pane.close paneState if pane.isOpen paneState
  if hit == "play"
    playback.play playbackState
    fastPlayMouse = true
    syncFastMode!
  elseif hit == "pause"
    playback.pause playbackState
  elseif hit == "step"
    stepForward!
  elseif hit == "restart"
    restartWorld!

love.mousereleased = (x, y, button) ->
  return unless button == 1
  if fastPlayMouse
    fastPlayMouse = false
    syncFastMode!
