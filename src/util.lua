local M = {}

function M.wrap(index, size)
  return ((index - 1) % size) + 1
end

return M
