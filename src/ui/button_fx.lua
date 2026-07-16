-- Reusable button transition: expanding outline with fading trail copies.
-- Attach to any {x, y, w, h} rect — not tied to statusbar internals.
local M = {}

local PHASE_IDLE = "idle"
local PHASE_ACTIVE = "active"

local function easeOutQuad(t)
  return 1 - (1 - t) * (1 - t)
end

local function resolveConfig(config)
  config = config or {}
  return {
    enabled = config.buttonFxEnabled ~= false,
    durationSec = config.buttonFxDurationSec or 0.4,
    trailCount = config.buttonFxTrailCount or 3,
    trailSpacingSec = config.buttonFxTrailSpacingSec or 0.05,
    expandPx = config.buttonFxExpandPx or 10,
  }
end

function M.create(config)
  local resolved = resolveConfig(config)
  return {
    phase = PHASE_IDLE,
    elapsed = 0,
    targetId = nil,
    enabled = resolved.enabled,
    durationSec = resolved.durationSec,
    trailCount = resolved.trailCount,
    trailSpacingSec = resolved.trailSpacingSec,
    expandPx = resolved.expandPx,
  }
end

function M.isIdle(state)
  return state.phase == PHASE_IDLE
end

function M.isAnimating(state)
  return state.phase ~= PHASE_IDLE
end

function M.trigger(state, targetId)
  if not state.enabled then
    return false
  end

  state.phase = PHASE_ACTIVE
  state.elapsed = 0
  state.targetId = targetId
  return true
end

function M.cancel(state)
  state.phase = PHASE_IDLE
  state.elapsed = 0
  state.targetId = nil
end

function M.update(state, dt)
  if state.phase == PHASE_IDLE then
    return nil
  end

  if not state.enabled then
    M.cancel(state)
    return "done"
  end

  state.elapsed = state.elapsed + dt

  -- Keep the effect alive until the last trail has fully faded.
  local totalSec = state.durationSec + state.trailCount * state.trailSpacingSec
  if state.elapsed >= totalSec then
    M.cancel(state)
    return "done"
  end

  return nil
end

function M.progress(state)
  if state.phase == PHASE_IDLE or state.durationSec <= 0 then
    return 0
  end
  return math.min(1, state.elapsed / state.durationSec)
end

-- Pure geometry for tests and draw. Trails are delayed copies of the expanding outline.
function M.trailFrames(state, rect)
  if state.phase == PHASE_IDLE or not rect then
    return {}
  end

  local frames = {}
  local duration = state.durationSec
  if duration <= 0 then
    return frames
  end

  for i = 0, state.trailCount do
    local age = state.elapsed - i * state.trailSpacingSec
    if age >= 0 and age < duration then
      local t = age / duration
      local expand = easeOutQuad(t) * state.expandPx
      local trailFade = 1 - (i / (state.trailCount + 1))
      local alpha = (1 - t) * trailFade
      frames[#frames + 1] = {
        x = rect.x - expand,
        y = rect.y - expand,
        w = rect.w + expand * 2,
        h = rect.h + expand * 2,
        alpha = alpha,
        index = i,
      }
    end
  end

  return frames
end

function M.draw(state, rect, theme)
  if state.phase == PHASE_IDLE or not rect or not theme then
    return
  end

  local color = theme.accent or theme.alive or theme.grid
  if not color then
    return
  end

  local frames = M.trailFrames(state, rect)
  for _, frame in ipairs(frames) do
    love.graphics.setColor(color[1], color[2], color[3], frame.alpha)
    love.graphics.rectangle(
      "line",
      frame.x + 0.5,
      frame.y + 0.5,
      frame.w,
      frame.h
    )
  end
end

return M
