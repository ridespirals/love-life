local M = {}

local function fail(message)
  error(message or "assertion failed", 3)
end

function M.isTrue(value, message)
  if not value then
    fail(message or "expected true")
  end
end

function M.isFalse(value, message)
  if value then
    fail(message or "expected false")
  end
end

function M.equal(actual, expected, message)
  if actual ~= expected then
    fail(string.format(
      "%s\n  expected: %s\n    actual: %s",
      message or "values differ",
      tostring(expected),
      tostring(actual)
    ))
  end
end

return M
