local assert = require("tests.assert")

local M = {}

function M.test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: %s", name, err), 0)
  end
end

function M.aliveCount(world)
  local count = 0
  for row = 1, world.rows do
    for col = 1, world.cols do
      if world.current[row][col] then
        count = count + 1
      end
    end
  end
  return count
end

function M.withLoveMock(filesystem, fn)
  local previousLove = _G.love
  local ok, err = pcall(function()
    _G.love = {
      filesystem = filesystem,
    }
    fn()
  end)
  _G.love = previousLove
  if not ok then
    error(err, 0)
  end
end

function M.withLoveGraphicsMock(dimensions, fn)
  local previousLove = _G.love
  local ok, err = pcall(function()
    _G.love = {
      graphics = {
        getDimensions = function()
          return dimensions.width, dimensions.height
        end,
      },
    }
    fn()
  end)
  _G.love = previousLove
  if not ok then
    error(err, 0)
  end
end

return M
