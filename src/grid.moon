util = require "src.util"

create = (rows, cols) ->
  current = {}
  for row = 1, rows
    current[row] = {}
    for col = 1, cols
      current[row][col] = false
  nextCells = {}
  for row = 1, rows
    nextCells[row] = {}
    for col = 1, cols
      nextCells[row][col] = false
  rows: rows, cols: cols, current: current, next: nextCells

clear = (world) ->
  for row = 1, world.rows
    for col = 1, world.cols
      world.current[row][col] = false

setAlive = (world, row, col, alive) ->
  world.current[row][col] = alive

countNeighbors = (world, row, col) ->
  count = 0
  for dRow = -1, 1
    for dCol = -1, 1
      unless dRow == 0 and dCol == 0
        neighborRow = util.wrap row + dRow, world.rows
        neighborCol = util.wrap col + dCol, world.cols
        count += 1 if world.current[neighborRow][neighborCol]
  count

computeNext = (world, rules) ->
  for row = 1, world.rows
    for col = 1, world.cols
      alive = world.current[row][col]
      neighbors = countNeighbors world, row, col
      if alive
        world.next[row][col] = rules.survival[neighbors] == true
      else
        world.next[row][col] = rules.birth[neighbors] == true

step = (world, rules) ->
  world.current, world.next = world.next, world.current
  computeNext world, rules

isAlive = (world, row, col) ->
  world.current[row][col]

return {
  create: create, clear: clear, setAlive: setAlive
  countNeighbors: countNeighbors, computeNext: computeNext
  step: step, isAlive: isAlive
}
