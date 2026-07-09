PHASE_IDLE = "idle"
PHASE_PREVIEW = "preview"
PHASE_COMMIT = "commit"

resolveDurations = (config) ->
  if config.stepAnimPreviewSec and config.stepAnimCommitSec
    return config.stepAnimPreviewSec, config.stepAnimCommitSec
  total = config.stepAnimSec or 0.2
  total * 0.4, total * 0.6

create = (config) ->
  previewSec, commitSec = resolveDurations config
  {
    phase: PHASE_IDLE, elapsed: 0, enabled: config.stepAnimEnabled ~= false
    previewSec: previewSec, commitSec: commitSec, speedScale: 1
  }

setSpeedScale = (state, scale) ->
  state.speedScale = scale or 1

isIdle = (state) ->
  state.phase == PHASE_IDLE

isAnimating = (state) ->
  state.phase ~= PHASE_IDLE

begin = (state) ->
  return "commit_immediate" unless state.enabled
  return if state.phase ~= PHASE_IDLE
  state.phase = PHASE_PREVIEW
  state.elapsed = 0

cancel = (state) ->
  state.phase = PHASE_IDLE
  state.elapsed = 0

update = (state, dt) ->
  return if state.phase == PHASE_IDLE
  unless state.enabled
    state.phase = PHASE_IDLE
    state.elapsed = 0
    return "commit"
  duration = if state.phase == PHASE_PREVIEW then state.previewSec else state.commitSec
  state.elapsed += dt * state.speedScale
  return if state.elapsed < duration
  if state.phase == PHASE_PREVIEW
    state.phase = PHASE_COMMIT
    state.elapsed = 0
    return
  state.phase = PHASE_IDLE
  state.elapsed = 0
  "commit"

getPhaseT = (state) ->
  return PHASE_IDLE, 0 if state.phase == PHASE_IDLE
  duration = if state.phase == PHASE_PREVIEW then state.previewSec else state.commitSec
  return state.phase, 1 if duration <= 0
  state.phase, math.min(1, state.elapsed / duration)

getCellChange = (world, row, col) ->
  alive = world.current[row][col]
  nextAlive = world.next[row][col]
  return "death" if alive and not nextAlive
  return "birth" if not alive and nextAlive
  "unchanged"

return {
  create: create, setSpeedScale: setSpeedScale, isIdle: isIdle
  isAnimating: isAnimating, begin: begin, cancel: cancel, update: update
  getPhaseT: getPhaseT, getCellChange: getCellChange
}
