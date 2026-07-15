local config = require("src.config")
local themes = require("src.themes")
local rules = require("src.rules")
local grid = require("src.grid")
local patterns = require("src.patterns")
local playback = require("src.playback")
local renderer = require("src.renderer")
local statusbar = require("src.ui.statusbar")
local pane = require("src.ui.pane")
local session = require("src.session")
local rule_pane = require("src.ui.panes.rule_pane")
local theme_pane = require("src.ui.panes.theme_pane")
local board = require("src.input.board")
local layout = require("src.layout")
local settings_pane = require("src.ui.panes.settings_pane")
local stepAnimation = require("src.step_animation")
local userdata = require("src.userdata")
local color_picker = require("src.ui.color_picker")
local color = require("src.color")

local world
local theme
local activeRule
local playbackState
local animState
local generation = 0
local fastMode = false
local fastKeyboard = false
local fastPlayMouse = false
local paneState
local sessionState
local colorPickerState
local boardState
local FAST_STEP_INTERVAL = 0.05
local FAST_ANIM_SPEED_MULTIPLIER = 4

local function syncDraftForPane(id)
  if id == "rule" then
    session.resetRuleDraft(sessionState, activeRule)
  elseif id == "theme" then
    session.resetThemeDraft(sessionState, theme, themes)
  elseif id == "pattern" then
    session.resetPatternDraft(sessionState, sessionState.appliedPatternId)
  elseif id == "settings" then
    session.resetGridDraft(sessionState, config)
  end
end

local function applyRuleDraft()
  local rule = rule_pane.apply(sessionState)
  if not rule then
    return
  end

  -- Apply policy: pause and recompute next state; board cells preserved (see AGENTS.md).
  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  activeRule = rule
  sessionState.appliedRuleId = rule.name
  sessionState.draftRulePresetId = rule.name
  sessionState.draftRuleName = sessionState.draftRuleName or rule.name
  grid.computeNext(world, activeRule)
  pane.close(paneState)
end

local function applyThemeDraft()
  local nextTheme = theme_pane.apply(sessionState)
  if not nextTheme then
    return
  end

  -- Apply policy: live swap; playback continues; pane stays open for browsing.
  theme = nextTheme
  sessionState.appliedThemeId = nextTheme.name
end

local function saveRuleDraft()
  local id = userdata.slugify(sessionState.draftRuleName or "")
  if id == "" then
    return
  end
  if rules.isBuiltin(id) then
    return
  end

  local rule = rule_pane.apply(sessionState)
  if not rule then
    return
  end

  local saved = userdata.save("rules", id, {
    id = id,
    name = sessionState.draftRuleName,
    rulestring = rule.rulestring,
  })
  if not saved then
    return
  end

  rules.loadUser(userdata)
  local loaded = rules.get(id)
  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  activeRule = loaded
  sessionState.appliedRuleId = id
  sessionState.draftRulePresetId = id
  sessionState.draftRuleString = loaded.rulestring
  sessionState.draftRuleName = id
  grid.computeNext(world, activeRule)
end

local function deleteRuleDraft()
  local id = sessionState.draftRulePresetId
  if not rules.isUser(id) then
    return
  end

  userdata.delete("rules", id)
  rules.loadUser(userdata)

  local fallback = rules.get("conway")
  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  activeRule = fallback
  sessionState.appliedRuleId = fallback.name
  session.resetRuleDraft(sessionState, fallback)
  grid.computeNext(world, activeRule)
end

local function saveThemeDraft()
  local id = userdata.slugify(sessionState.draftThemeName or "")
  if id == "" then
    return
  end
  if themes.isBuiltin(id) then
    return
  end

  local built = theme_pane.apply(sessionState)
  if not built then
    return
  end

  local colors = themes.colorsToRgb(built)
  local record = {
    id = id,
    name = sessionState.draftThemeName,
    alive = colors.alive,
    dead = colors.dead,
    grid = colors.grid,
    background = colors.background,
  }
  if colors.accent then
    record.accent = colors.accent
  end

  local saved = userdata.save("themes", id, record)
  if not saved then
    return
  end

  themes.loadUser(userdata)
  local loaded = themes.get(id)
  theme = loaded
  sessionState.appliedThemeId = id
  sessionState.draftThemePresetId = id
  sessionState.draftThemeColors = themes.colorsToHex(loaded)
  sessionState.draftThemeName = id
end

local function deleteThemeDraft()
  local id = sessionState.draftThemePresetId
  if not themes.isUser(id) then
    return
  end

  userdata.delete("themes", id)
  themes.loadUser(userdata)

  local fallback = themes.get("classic")
  theme = fallback
  sessionState.appliedThemeId = fallback.name
  session.resetThemeDraft(sessionState, fallback, themes)
end

local function consumeColorPickerResult()
  local result = color_picker.takeResult(colorPickerState)
  if not result or not result.confirmed then
    return
  end
  theme_pane.applyColorPick(sessionState, result.field, result.color)
  applyThemeDraft()
end

local function openColorPickerForField(field)
  local colors = sessionState.draftThemeColors or {}
  local initial = colors[field]
  if field == "accent" and (not initial or initial == "") then
    initial = color.rgb(1, 1, 1)
  end
  color_picker.open(colorPickerState, initial, field)
end

local function togglePane(id, anchor)
  if paneState.openId ~= id then
    syncDraftForPane(id)
  end
  pane.toggle(paneState, id, anchor)
end

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

local function syncFastMode()
  fastMode = fastKeyboard or fastPlayMouse
  applyStepInterval()
  applyAnimSpeed()
end

local function reloadAppliedPattern()
  local patternId = sessionState.appliedPatternId
  if patternId == "custom" then
    grid.clear(world)
    grid.computeNext(world, activeRule)
    playback.restart(playbackState)
    generation = 0
    return
  end
  if not patterns.exists(patternId) then
    patternId = config.defaultPattern
  end

  patterns.apply(world, patternId)
  grid.computeNext(world, activeRule)
  playback.restart(playbackState)
  generation = 0
  sessionState.appliedPatternId = patternId
end

local function applyAutoGridSize()
  local windowWidth, windowHeight = love.graphics.getDimensions()
  config.rows, config.cols = layout.computeGridSize(
    windowWidth,
    windowHeight,
    config.tileSize,
    config.statusBarHeight
  )
end

local function resetSimulation(opts)
  stepAnimation.cancel(animState)

  if opts and opts.resize then
    if sessionState.gridMode == "auto" then
      applyAutoGridSize()
      world = grid.create(config.rows, config.cols)
    end
  elseif opts and opts.rebuild then
    world = grid.create(config.rows, config.cols)
  end

  reloadAppliedPattern()
end

local function restartWorld()
  resetSimulation()
end

local function applyPatternDraft()
  local id = sessionState.draftPatternId
  if not id or not patterns.exists(id) then
    return
  end

  -- Apply policy: pause and reload the board from the picked pattern.
  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  patterns.apply(world, id)
  grid.computeNext(world, activeRule)
  generation = 0
  sessionState.appliedPatternId = id
  pane.close(paneState)
end

local function clearBoard()
  -- "New pattern" workflow: blank paused board, ready for drawing.
  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  grid.clear(world)
  grid.computeNext(world, activeRule)
  generation = 0
  sessionState.appliedPatternId = "custom"
  pane.close(paneState)
end

local function savePatternDraft()
  local id = userdata.slugify(sessionState.draftPatternName or "")
  if id == "" then
    return
  end
  if patterns.isBuiltin(id) then
    return
  end

  local exported = patterns.fromWorld(world)
  local saved = userdata.save("patterns", id, {
    id = id,
    name = sessionState.draftPatternName,
    cells = exported.cells,
  })
  if not saved then
    return
  end

  patterns.loadUser(userdata)
  sessionState.appliedPatternId = id
  session.resetPatternDraft(sessionState, id)
end

local function deletePatternDraft()
  local id = sessionState.draftPatternId
  if not patterns.isUser(id) then
    return
  end

  userdata.delete("patterns", id)
  patterns.loadUser(userdata)

  if sessionState.appliedPatternId == id then
    sessionState.appliedPatternId = config.defaultPattern
    resetSimulation()
  end
  session.resetPatternDraft(sessionState, sessionState.appliedPatternId)
end

local function canDrawOnBoard()
  return not playbackState.running
    and not pane.isOpen(paneState)
    and not color_picker.isOpen(colorPickerState)
    and stepAnimation.isIdle(animState)
end

local function boardCellAt(x, y)
  return board.screenToCell(x, y, renderer.getLayout(config), world)
end

local function markBoardEdited()
  grid.computeNext(world, activeRule)
  sessionState.appliedPatternId = "custom"
end

local function tryBeginBoardStroke(x, y, button)
  if not canDrawOnBoard() then
    return false
  end

  local row, col = boardCellAt(x, y)
  if not row then
    return false
  end

  board.beginStroke(boardState, world, row, col, button)
  markBoardEdited()
  return true
end

local function rebuildWorldForWindow()
  if sessionState.gridMode == "auto" then
    resetSimulation({ resize = true })
  end
end

local function applyGridSettings()
  local settings = settings_pane.apply(sessionState, config)
  if not settings then
    return
  end

  playback.pause(playbackState)
  stepAnimation.cancel(animState)
  sessionState.gridMode = settings.mode
  config.gridMode = settings.mode
  config.tileSize = settings.tileSize

  if settings.mode == "forced" then
    config.forcedRows = settings.forcedRows
    config.forcedCols = settings.forcedCols
    config.forcedTileSize = settings.forcedTileSize
    config.rows = settings.rows
    config.cols = settings.cols
  else
    applyAutoGridSize()
  end

  resetSimulation({ rebuild = true })
  session.resetGridDraft(sessionState, config)
  pane.close(paneState)
end

local function toggleFullscreen()
  local fullscreen, fstype = love.window.getFullscreen()
  love.window.setFullscreen(not fullscreen, fstype or "desktop")
end

function love.load()
  userdata.ensureDirs()
  rules.loadUser(userdata)
  themes.loadUser(userdata)
  patterns.loadUser(userdata)

  activeRule = rules.get(config.activeRule)
  theme = themes.get(config.activeTheme)
  playbackState = playback.create(config.stepInterval)
  animState = stepAnimation.create(config)
  sessionState = session.create({
    ruleId = config.activeRule,
    themeId = config.activeTheme,
    patternId = config.defaultPattern,
    gridMode = config.gridMode or "auto",
  })
  paneState = pane.create()
  colorPickerState = color_picker.create()
  boardState = board.create()
  fastMode = false
  applyAnimSpeed()
  if sessionState.gridMode == "forced" then
    config.rows = config.forcedRows
    config.cols = config.forcedCols
    config.tileSize = config.forcedTileSize
    world = grid.create(config.rows, config.cols)
    reloadAppliedPattern()
  else
    rebuildWorldForWindow()
  end
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
  statusbar.draw(
    world,
    theme,
    config,
    activeRule,
    generation,
    sessionState.appliedPatternId,
    fastMode,
    paneState
  )
  pane.draw(paneState, theme, config, sessionState)
  if pane.isOpen(paneState) then
    statusbar.drawOpenerLabel(
      world,
      theme,
      config,
      activeRule,
      generation,
      sessionState.appliedPatternId,
      fastMode,
      paneState.anchor
    )
  end
  color_picker.draw(colorPickerState, theme, config)
end

function love.keypressed(key)
  if color_picker.keypressed(colorPickerState, key) then
    consumeColorPickerResult()
    return
  end

  if key == "escape" then
    if pane.isOpen(paneState) then
      pane.close(paneState)
      return
    end
  end

  if pane.isOpen(paneState) then
    local paneAction = pane.keypressed(paneState, sessionState, key)
    if paneAction then
      return
    end
    if key ~= "q" then
      return
    end
  end

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
    fastKeyboard = true
    syncFastMode()
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
    fastKeyboard = false
    syncFastMode()
  end
end

function love.textinput(text)
  if color_picker.isOpen(colorPickerState) then
    return
  end
  if pane.isOpen(paneState) then
    pane.textinput(paneState, sessionState, text)
  end
end

function love.mousepressed(x, y, button)
  if button == 2 then
    tryBeginBoardStroke(x, y, 2)
    return
  end

  if button ~= 1 then
    return
  end

  if color_picker.mousepressed(colorPickerState, x, y) then
    consumeColorPickerResult()
    return
  end

  if pane.hitTestClose(config, paneState, x, y) then
    pane.close(paneState)
    return
  end

  local chipPane, chipAnchor = statusbar.hitTestChip(
    world,
    theme,
    config,
    activeRule,
    generation,
    sessionState.appliedPatternId,
    x,
    y
  )
  if chipPane then
    togglePane(chipPane, chipAnchor)
    return
  end

  local hit = statusbar.hitTestButton(config, x, y, fastMode)
  if hit == "settings" then
    togglePane("settings", statusbar.getButton(config, fastMode, "settings"))
    return
  end

  if pane.hitTestPane(config, paneState, x, y) then
    local action = pane.mousepressed(paneState, sessionState, x, y, theme, config)
    if action == "apply_rule" then
      applyRuleDraft()
    elseif action == "apply_theme" then
      applyThemeDraft()
    elseif action == "save_rule" then
      saveRuleDraft()
    elseif action == "delete_rule" then
      deleteRuleDraft()
    elseif action == "save_theme" then
      saveThemeDraft()
    elseif action == "delete_theme" then
      deleteThemeDraft()
    elseif action == "apply_pattern" then
      applyPatternDraft()
    elseif action == "clear_board" then
      clearBoard()
    elseif action == "save_pattern" then
      savePatternDraft()
    elseif action == "delete_pattern" then
      deletePatternDraft()
    elseif action == "apply_grid" then
      applyGridSettings()
    elseif action == "open_color_picker" then
      openColorPickerForField(sessionState.colorPickField)
    end
    return
  end

  local dismissedPane = false
  if pane.isOpen(paneState) then
    pane.close(paneState)
    dismissedPane = true
  end

  if hit == "play" then
    playback.play(playbackState)
    fastPlayMouse = true
    syncFastMode()
  elseif hit == "pause" then
    playback.pause(playbackState)
  elseif hit == "step" then
    stepForward()
  elseif hit == "restart" then
    restartWorld()
  end
  if hit or dismissedPane then
    return
  end

  tryBeginBoardStroke(x, y, 1)
end

function love.mousemoved(x, y)
  color_picker.mousemoved(colorPickerState, x, y)

  if pane.isOpen(paneState) then
    pane.mousemoved(paneState, sessionState, x, y, theme, config)
  end

  if board.isDrawing(boardState) then
    local row, col = boardCellAt(x, y)
    if row and board.continueStroke(boardState, world, row, col) then
      markBoardEdited()
    end
  end
end

function love.mousereleased(x, y, button)
  if button == 2 then
    board.endStroke(boardState)
    return
  end

  if button ~= 1 then
    return
  end

  if pane.isOpen(paneState) then
    pane.mousereleased(paneState, sessionState)
  end

  color_picker.mousereleased(colorPickerState)
  board.endStroke(boardState)

  if fastPlayMouse then
    fastPlayMouse = false
    syncFastMode()
  end
end
