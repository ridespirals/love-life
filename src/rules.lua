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

function M.fromRulestring(rulestring)
  return preset("custom", rulestring)
end

function M.tryFromRulestring(rulestring)
  local ok, rule = pcall(M.fromRulestring, rulestring)
  if ok then
    return rule
  end
end

function M.get(name)
  return rulePresets[name] or rulePresets[defaultRule]
end

function M.list()
  local names = {}
  for name in pairs(rulePresets) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return M
