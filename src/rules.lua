local M = {}

local defaultRule = "conway"

local function digitSet(digits)
  local set = {}
  for digit in digits:gmatch("%d") do
    set[tonumber(digit)] = true
  end
  return set
end

function M.parse(rulestring)
  local birthDigits, survivalDigits = rulestring:match("^B([0-9]+)/S([0-9]+)$")
  if not birthDigits or not survivalDigits then
    error("invalid rulestring: " .. tostring(rulestring), 2)
  end

  return {
    birth = digitSet(birthDigits),
    survival = digitSet(survivalDigits),
  }
end

local function preset(name, rulestring)
  local parsed = M.parse(rulestring)
  return {
    name = name,
    rulestring = rulestring,
    birth = parsed.birth,
    survival = parsed.survival,
  }
end

local rulePresets = {
  conway = preset("conway", "B3/S23"),
  ant_colony = preset("ant_colony", "B3/S234"),
}

local userRules = {}

function M.fromRulestring(rulestring)
  return preset("custom", rulestring)
end

function M.tryFromRulestring(rulestring)
  local ok, rule = pcall(M.fromRulestring, rulestring)
  if ok then
    return rule
  end
end

function M.isBuiltin(id)
  return rulePresets[id] ~= nil
end

function M.isUser(id)
  return userRules[id] ~= nil
end

function M.loadUser(userdata)
  userRules = {}
  if not userdata then
    return
  end

  for _, id in ipairs(userdata.list("rules")) do
    if not rulePresets[id] then
      local data = userdata.load("rules", id)
      if data then
        local ok, rule = pcall(preset, id, data.rulestring)
        if ok then
          userRules[id] = rule
        end
      end
    end
  end
end

function M.get(name)
  return rulePresets[name] or userRules[name] or rulePresets[defaultRule]
end

function M.list()
  local names = {}
  local seen = {}

  local function addSorted(source)
    local batch = {}
    for id in pairs(source) do
      batch[#batch + 1] = id
    end
    table.sort(batch)
    for _, id in ipairs(batch) do
      if not seen[id] then
        seen[id] = true
        names[#names + 1] = id
      end
    end
  end

  addSorted(rulePresets)
  addSorted(userRules)
  return names
end

return M
