local M = {}

local PHASE_IDLE = "idle"
local PHASE_MORPH = "morph"

function M.create(config)
  return {
    phase = PHASE_IDLE,
    elapsed = 0,
    enabled = config.stepAnimEnabled ~= false,
    durationSec = config.stepAnimSec or 0.2,
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

  state.phase = PHASE_MORPH
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

  state.elapsed = state.elapsed + dt * state.speedScale

  if state.elapsed < state.durationSec then
    return nil
  end

  state.phase = PHASE_IDLE
  state.elapsed = 0
  return "commit"
end

function M.getMorphT(state)
  if state.phase == PHASE_IDLE then
    return 0
  end

  if state.durationSec <= 0 then
    return 1
  end

  return math.min(1, state.elapsed / state.durationSec)
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
