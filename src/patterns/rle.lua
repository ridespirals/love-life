local M = {}

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

function M.parse(text)
  local name
  local headerSeen = false
  local rulestring
  local bodyParts = {}

  for rawLine in text:gmatch("[^\r\n]+") do
    local line = trim(rawLine)
    if line ~= "" then
      if line:match("^#") then
        local headerName = line:match("^#N%s+(.+)$")
        if headerName and not name then
          name = trim(headerName)
        end
      elseif line:match("^x%s*=") then
        headerSeen = true
        local rule = line:match("rule%s*=%s*([^,%s]+)")
        if rule then
          rulestring = trim(rule)
        end
      else
        bodyParts[#bodyParts + 1] = line
      end
    end
  end

  if not headerSeen then
    error("RLE missing header", 2)
  end
  if #bodyParts == 0 then
    error("RLE missing body", 2)
  end

  local body = table.concat(bodyParts, "")
  local cells = {}
  local col = 0
  local row = 0
  local count = ""
  local ended = false

  for index = 1, #body do
    local token = body:sub(index, index)
    if token:match("%d") then
      count = count .. token
    elseif token == "o" or token == "b" then
      local run = tonumber(count) or 1
      if token == "o" then
        for offset = 0, run - 1 do
          cells[#cells + 1] = { col + offset, row }
        end
      end
      col = col + run
      count = ""
    elseif token == "$" then
      local run = tonumber(count) or 1
      row = row + run
      col = 0
      count = ""
    elseif token == "!" then
      ended = true
      break
    elseif token:match("%s") then
      -- Ignore whitespace in body.
    else
      error("RLE invalid token: " .. token, 2)
    end
  end

  if not ended then
    error("RLE missing terminator '!'", 2)
  end

  return {
    id = nil,
    name = name,
    rulestring = rulestring,
    cells = cells,
  }
end

return M
