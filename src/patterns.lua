local grid = require("src.grid")
local rle = require("src.patterns.rle")
local util = require("src.util")

local M = {}

-- Fallback when get(nil) or unknown id resolution fails; app startup uses config.defaultPattern.
local defaultPattern = "glider"

-- Curated repo catalog: .lua modules and patterns/*.rle assets shipped with the game.
local builtinIds = {
  "backrake_1",
  "beacon",
  "blinker",
  "bomber",
  "circle_of_fire",
  "copperhead",
  "cottonmouth",
  "diamond",
  "fireship",
  "glider",
  "gosper_glider_gun",
  "lifeview",
  "loafer",
  "moose_antlers",
  "noahs_ark",
  "pulsar",
  "pulsar_on_pentadecathlon_i",
  "sidecar",
  "still_life_tagalong",
}

local builtinSet = {}
for _, id in ipairs(builtinIds) do
  builtinSet[id] = true
end

local userPatterns = {}

local function getBounds(cells)
  local minCol, maxCol = math.huge, -math.huge
  local minRow, maxRow = math.huge, -math.huge

  for _, cell in ipairs(cells) do
    local col = cell[1]
    local row = cell[2]
    minCol = math.min(minCol, col)
    maxCol = math.max(maxCol, col)
    minRow = math.min(minRow, row)
    maxRow = math.max(maxRow, row)
  end

  return minCol, maxCol, minRow, maxRow
end

local function loadRlePattern(id)
  if not (love and love.filesystem and love.filesystem.getInfo and love.filesystem.read) then
    return nil
  end

  local path = "patterns/" .. id .. ".rle"
  if not love.filesystem.getInfo(path, "file") then
    return nil
  end

  local text = love.filesystem.read(path)
  local pattern = rle.parse(text)
  pattern.id = id
  if not pattern.name or pattern.name == "" then
    pattern.name = id
  end
  return pattern
end

function M.isBuiltin(id)
  return builtinSet[id] == true
end

function M.isUser(id)
  return userPatterns[id] ~= nil
end

-- True when id resolves to a catalog entry without hitting the glider fallback.
function M.exists(id)
  return builtinSet[id] == true or userPatterns[id] ~= nil
end

function M.loadUser(userdata)
  userPatterns = {}
  if not userdata then
    return
  end

  for _, id in ipairs(userdata.list("patterns")) do
    if not builtinSet[id] then
      local data = userdata.load("patterns", id)
      if data then
        userPatterns[id] = {
          id = id,
          name = data.name or id,
          cells = data.cells,
        }
      end
    end
  end
end

function M.get(id)
  local moduleId = id or defaultPattern

  if userPatterns[moduleId] and not builtinSet[moduleId] then
    return userPatterns[moduleId]
  end

  local ok, pattern = pcall(require, "patterns." .. moduleId)
  if ok then
    return pattern
  end

  local rlePattern = loadRlePattern(moduleId)
  if rlePattern then
    return rlePattern
  end

  ok, pattern = pcall(require, "patterns." .. defaultPattern)
  if ok then
    return pattern
  end

  error("pattern not found: " .. tostring(moduleId))
end

function M.list()
  local ids = {}
  for _, id in ipairs(builtinIds) do
    ids[#ids + 1] = id
  end

  local userIds = {}
  for id in pairs(userPatterns) do
    userIds[#userIds + 1] = id
  end
  table.sort(userIds)
  for _, id in ipairs(userIds) do
    ids[#ids + 1] = id
  end

  return ids
end

function M.stamp(world, pattern)
  grid.clear(world)

  if #pattern.cells == 0 then
    return
  end

  local minCol, maxCol, minRow, maxRow = getBounds(pattern.cells)
  local width = maxCol - minCol + 1
  local height = maxRow - minRow + 1

  local originCol = math.floor((world.cols - width) / 2) + 1 - minCol
  local originRow = math.floor((world.rows - height) / 2) + 1 - minRow

  for _, cell in ipairs(pattern.cells) do
    local col = util.wrap(originCol + cell[1], world.cols)
    local row = util.wrap(originRow + cell[2], world.rows)
    grid.setAlive(world, row, col, true)
  end
end

function M.apply(world, patternId)
  M.stamp(world, M.get(patternId))
end

-- Export the current board as pattern cells ({col,row} pairs, zero-based,
-- cropped to the live bounding box) so drawings can be saved and re-stamped.
function M.fromWorld(world)
  local cells = {}
  for row = 1, world.rows do
    for col = 1, world.cols do
      if world.current[row][col] then
        cells[#cells + 1] = { col - 1, row - 1 }
      end
    end
  end

  if #cells == 0 then
    return { cells = {} }
  end

  local minCol, _, minRow = getBounds(cells)
  for _, cell in ipairs(cells) do
    cell[1] = cell[1] - minCol
    cell[2] = cell[2] - minRow
  end

  return { cells = cells }
end

return M
