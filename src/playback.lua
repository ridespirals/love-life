local M = {}

function M.create(stepInterval)
  return {
    running = false,
    stepInterval = stepInterval,
    accumulator = 0,
  }
end

function M.play(state)
  state.running = true
end

function M.pause(state)
  state.running = false
end

function M.toggle(state)
  state.running = not state.running
end

function M.stepForward(state, advance)
  advance()
  state.accumulator = 0
end

function M.restart(state)
  state.running = false
  state.accumulator = 0
end

function M.update(state, dt, advance)
  if not state.running then
    return
  end

  state.accumulator = state.accumulator + dt
  while state.accumulator >= state.stepInterval do
    state.accumulator = state.accumulator - state.stepInterval
    advance()
  end
end

return M
