create = (stepInterval) ->
  running: false, stepInterval: stepInterval, accumulator: 0

play = (state) ->
  state.running = true

pause = (state) ->
  state.running = false

toggle = (state) ->
  state.running = not state.running

stepForward = (state, advance) ->
  advance!
  state.accumulator = 0

restart = (state) ->
  state.running = false
  state.accumulator = 0

setStepInterval = (state, stepInterval) ->
  state.stepInterval = stepInterval

update = (state, dt, advance) ->
  return unless state.running
  state.accumulator += dt
  while state.accumulator >= state.stepInterval
    state.accumulator -= state.stepInterval
    advance!

return {
  create: create, play: play, pause: pause, toggle: toggle
  stepForward: stepForward, restart: restart
  setStepInterval: setStepInterval, update: update
}
