local M = {}

local VALID_TYPES = {
  rules = true,
  themes = true,
  patterns = true,
}

local function assertType(assetType)
  if not VALID_TYPES[assetType] then
    error("invalid userdata type: " .. tostring(assetType), 2)
  end
end

function M.slugify(name)
  if not name or name == "" then
    return ""
  end
  local slug = name:lower()
  slug = slug:gsub("[%s%-]+", "_")
  slug = slug:gsub("[^a-z0-9_]", "")
  slug = slug:gsub("_+", "_")
  slug = slug:gsub("^_", ""):gsub("_$", "")
  return slug
end

local function escapeString(value)
  return string.format("%q", value)
end

local function serializeValue(value, indent)
  local t = type(value)
  if t == "string" then
    return escapeString(value)
  elseif t == "number" then
    if value ~= value or value == math.huge or value == -math.huge then
      error("cannot serialize non-finite number", 2)
    end
    return tostring(value)
  elseif t == "boolean" then
    return value and "true" or "false"
  elseif t == "table" then
    local parts = {}
    local nextIndent = indent .. "  "
    local keys = {}
    for key in pairs(value) do
      keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
      return tostring(a) < tostring(b)
    end)
    for _, key in ipairs(keys) do
      local keyType = type(key)
      local keyLit
      if keyType == "string" and key:match("^[%a_][%w_]*$") then
        keyLit = key
      elseif keyType == "string" or keyType == "number" then
        keyLit = "[" .. serializeValue(key, nextIndent) .. "]"
      else
        error("cannot serialize table key of type " .. keyType, 2)
      end
      parts[#parts + 1] = nextIndent .. keyLit .. " = " .. serializeValue(value[key], nextIndent) .. ","
    end
    if #parts == 0 then
      return "{}"
    end
    return "{\n" .. table.concat(parts, "\n") .. "\n" .. indent .. "}"
  end
  error("cannot serialize value of type " .. t, 2)
end

function M.serialize(data)
  if type(data) ~= "table" then
    error("serialize expects a table", 2)
  end
  return "return " .. serializeValue(data, "") .. "\n"
end

function M.deserialize(chunk)
  if type(chunk) ~= "string" then
    return nil
  end

  local fn, err = load(chunk, "userdata", "t", {})
  if not fn then
    return nil, err
  end

  local ok, result = pcall(fn)
  if not ok or type(result) ~= "table" then
    return nil, result
  end
  return result
end

local function isHexColor(value)
  return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

function M.validate(assetType, data)
  assertType(assetType)
  if type(data) ~= "table" then
    return nil, "data must be a table"
  end
  if type(data.id) ~= "string" or data.id == "" then
    return nil, "missing id"
  end
  if type(data.name) ~= "string" or data.name == "" then
    return nil, "missing name"
  end

  if assetType == "rules" then
    if type(data.rulestring) ~= "string" then
      return nil, "missing rulestring"
    end
    return data
  end

  if assetType == "themes" then
    for _, key in ipairs({ "alive", "dead", "grid", "background" }) do
      if not isHexColor(data[key]) then
        return nil, "invalid " .. key
      end
    end
    if data.accent ~= nil and data.accent ~= "" and not isHexColor(data.accent) then
      return nil, "invalid accent"
    end
    return data
  end

  if assetType == "patterns" then
    if type(data.cells) ~= "table" then
      return nil, "missing cells"
    end
    return data
  end

  return nil, "unsupported type"
end

local function pathFor(assetType, id)
  return assetType .. "/" .. id .. ".lua"
end

function M.ensureDirs()
  if not love or not love.filesystem then
    return
  end
  for assetType in pairs(VALID_TYPES) do
    love.filesystem.createDirectory(assetType)
  end
end

function M.list(assetType)
  assertType(assetType)
  if not love or not love.filesystem then
    return {}
  end

  local dirInfo = love.filesystem.getInfo(assetType, "directory")
  if not dirInfo then
    return {}
  end

  local ids = {}
  local items = love.filesystem.getDirectoryItems(assetType)
  for _, filename in ipairs(items) do
    local id = filename:match("^(.+)%.lua$")
    if id and love.filesystem.getInfo(pathFor(assetType, id), "file") then
      ids[#ids + 1] = id
    end
  end
  table.sort(ids)
  return ids
end

function M.load(assetType, id)
  assertType(assetType)
  if not love or not love.filesystem then
    return nil
  end

  local path = pathFor(assetType, id)
  local info = love.filesystem.getInfo(path, "file")
  if not info then
    return nil
  end

  local chunk = love.filesystem.read(path)
  local data = M.deserialize(chunk)
  if not data then
    return nil
  end

  data.id = data.id or id
  local valid, err = M.validate(assetType, data)
  if not valid then
    return nil, err
  end
  return valid
end

function M.save(assetType, id, data)
  assertType(assetType)
  if not love or not love.filesystem then
    return nil, "love.filesystem unavailable"
  end

  local record = {}
  for key, value in pairs(data) do
    record[key] = value
  end
  record.id = id

  local valid, err = M.validate(assetType, record)
  if not valid then
    return nil, err
  end

  M.ensureDirs()
  local ok, writeErr = love.filesystem.write(pathFor(assetType, id), M.serialize(valid))
  if not ok then
    return nil, writeErr
  end
  return valid
end

function M.delete(assetType, id)
  assertType(assetType)
  if not love or not love.filesystem then
    return false
  end
  return love.filesystem.remove(pathFor(assetType, id))
end

return M
