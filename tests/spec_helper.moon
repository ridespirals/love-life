assert = require "tests.assert"

test = (name, fn) ->
  ok, err = pcall fn
  error("#{name}: #{err}", 0) unless ok

aliveCount = (world) ->
  count = 0
  for row = 1, world.rows
    for col = 1, world.cols
      count += 1 if world.current[row][col]
  count

withLoveMock = (filesystem, fn) ->
  previousLove = _G.love
  ok, err = pcall ->
    _G.love = filesystem: filesystem
    fn!
  _G.love = previousLove
  error(err, 0) unless ok

withLoveGraphicsMock = (dimensions, fn) ->
  previousLove = _G.love
  ok, err = pcall ->
    _G.love =
      graphics:
        getDimensions: -> dimensions.width, dimensions.height
    fn!
  _G.love = previousLove
  error(err, 0) unless ok

return {
  test: test, aliveCount: aliveCount
  withLoveMock: withLoveMock, withLoveGraphicsMock: withLoveGraphicsMock
}
