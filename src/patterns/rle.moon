trim = (value) ->
  value\match "^%s*(.-)%s*$"

parse = (text) ->
  name = nil
  headerSeen = false
  rulestring = nil
  bodyParts = {}

  for rawLine in text\gmatch "[^\r\n]+"
    line = trim rawLine
    if line ~= ""
      if line\match "^#"
        headerName = line\match "^#N%s+(.+)$"
        name = trim(headerName) if headerName and not name
      elseif line\match "^x%s*="
        headerSeen = true
        rule = line\match "rule%s*=%s*([^,%s]+)"
        rulestring = trim(rule) if rule
      else
        table.insert bodyParts, line

  error("RLE missing header", 2) unless headerSeen
  error("RLE missing body", 2) if #bodyParts == 0

  body = table.concat bodyParts, ""
  cells = {}
  col = 0
  row = 0
  count = ""
  ended = false

  for index = 1, #body
    token = body\sub index, index
    if token\match "%d"
      count ..= token
    elseif token == "o" or token == "b"
      run = tonumber(count) or 1
      if token == "o"
        for offset = 0, run - 1
          table.insert cells, { col + offset, row }
      col += run
      count = ""
    elseif token == "$"
      run = tonumber(count) or 1
      row += run
      col = 0
      count = ""
    elseif token == "!"
      ended = true
      break
    elseif not token\match "%s"
      error("RLE invalid token: #{token}", 2)

  error("RLE missing terminator '!'", 2) unless ended
  id: nil, name: name, rulestring: rulestring, cells: cells

return parse: parse
