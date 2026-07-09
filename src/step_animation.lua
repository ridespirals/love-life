local M = {}

local PHASE_IDLE = "idle"
local PHASE_PREVIEW = "preview"
local PHASE_COMMIT = "commit"

local function resolveDurations(config)
  if config.stepAnimPreviewSec and config.stepAnimCommitSec then
    return config.stepAnimPreviewSec, config.stepAnimCommitSec
  end

  local total = config.stepAnimSec or 0.2
  return total * 0.4, total * 0.6
end

function M.create(config)
  local previewSec, commitSec = resolveDurations(config)
  return {
    phase = PHASE_IDLE,
    elapsed = 0,
    enabled = config.stepAnimEnabled ~= false,
    previewSec = previewSec,
    commitSec = commitSec,
    speedScale = 1,
  }
end

function M.setSpeedScale(state, scale)
  state.speedScale = scale or 1
end

function M.isIdle(state)
  return state.phase == PHASE_IDLE
end

function M.isAnimating(state)
  return state.phase ~= PHASE_IDLE
end

function M.begin(state)
  if not state.enabled then
    return "commit_immediate"
  end

  if state.phase ~= PHASE_IDLE then
    return nil
  end

  state.phase = PHASE_PREVIEW
  state.elapsed = 0
  return nil
end

function M.cancel(state)
  state.phase = PHASE_IDLE
  state.elapsed = 0
end

function M.update(state, dt)
  if state.phase == PHASE_IDLE then
    return nil
  end

  if not state.enabled then
    state.phase = PHASE_IDLE
    state.elapsed = 0
    return "commit"
  end

  local duration = state.phase == PHASE_PREVIEW and state.previewSec or state.commitSec
  state.elapsed = state.elapsed + dt * state.speedScale

  if state.elapsed < duration then
    return nil
  end

  if state.phase == PHASE_PREVIEW then
    state.phase = PHASE_COMMIT
    state.elapsed = 0
    return nil
  end

  state.phase = PHASE_IDLE
  state.elapsed = 0
  return "commit"
end

function M.getPhaseT(state)
  if state.phase == PHASE_IDLE then
    return PHASE_IDLE, 0
  end

  local duration = state.phase == PHASE_PREVIEW and state.previewSec or state.commitSec
  if duration <= 0 then
    return state.phase, 1
  end

  return state.phase, math.min(1, state.elapsed / duration)
end

function M.getCellChange(world, row, col)
  local alive = world.current[row][col]
  local nextAlive = world.next[row][col]

  if alive and not nextAlive then
    return "death"
  end
  if not alive and nextAlive then
    return "birth"
  end
  return "unchanged"
end

return M
