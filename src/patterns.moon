grid = require "src.grid"
rle = require "src.patterns.rle"
util = require "src.util"

defaultPattern = "glider"

getBounds = (cells) ->
  minCol, maxCol = math.huge, -math.huge
  minRow, maxRow = math.huge, -math.huge
  for _, cell in ipairs cells
    col = cell[1]
    row = cell[2]
    minCol = math.min minCol, col
    maxCol = math.max maxCol, col
    minRow = math.min minRow, row
    maxRow = math.max maxRow, row
  minCol, maxCol, minRow, maxRow

loadRlePattern = (id) ->
  return unless love and love.filesystem and love.filesystem.getInfo and love.filesystem.read
  path = "patterns/#{id}.rle"
  return unless love.filesystem.getInfo path, "file"
  text = love.filesystem.read path
  pattern = rle.parse text
  pattern.id = id
  pattern.name = id if not pattern.name or pattern.name == ""
  pattern

get = (id) ->
  moduleId = id or defaultPattern
  ok, pattern = pcall require, "patterns." .. moduleId
  return pattern if ok
  rlePattern = loadRlePattern moduleId
  return rlePattern if rlePattern
  ok, pattern = pcall require, "patterns." .. defaultPattern
  return pattern if ok
  error "pattern not found: #{tostring moduleId}"

list = ->
  {
    "backrake_1", "beacon", "blinker", "bomber", "circle_of_fire",
    "copperhead", "cottonmouth", "diamond", "fireship", "glider",
    "gosper_glider_gun", "lifeview", "loafer", "moose_antlers", "noahs_ark",
    "pulsar", "pulsar_on_pentadecathlon_i", "sidecar", "still_life_tagalong",
  }

stamp = (world, pattern) ->
  grid.clear world
  return if #pattern.cells == 0
  minCol, maxCol, minRow, maxRow = getBounds pattern.cells
  width = maxCol - minCol + 1
  height = maxRow - minRow + 1
  originCol = math.floor((world.cols - width) / 2) + 1 - minCol
  originRow = math.floor((world.rows - height) / 2) + 1 - minRow
  for _, cell in ipairs pattern.cells
    col = util.wrap originCol + cell[1], world.cols
    row = util.wrap originRow + cell[2], world.rows
    grid.setAlive world, row, col, true

apply = (world, patternId) ->
  stamp world, get(patternId)

return get: get, list: list, stamp: stamp, apply: apply
