fail = (message) ->
  error(message or "assertion failed", 3)

isTrue = (value, message) ->
  fail(message or "expected true") unless value

isFalse = (value, message) ->
  fail(message or "expected false") if value

equal = (actual, expected, message) ->
  return if actual == expected
  fail string.format(
    "%s\n  expected: %s\n    actual: %s",
    message or "values differ",
    tostring(expected),
    tostring(actual)
  )

return isTrue: isTrue, isFalse: isFalse, equal: equal
