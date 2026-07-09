defaultRule = "conway"

digitSet = (digits) ->
  set = {}
  for digit in digits\gmatch "%d"
    set[tonumber(digit)] = true
  set

parse = (rulestring) ->
  birthDigits, survivalDigits = rulestring\match "^B([0-9]+)/S([0-9]+)$"
  error("invalid rulestring: #{rulestring}", 2) unless birthDigits and survivalDigits
  birth: digitSet(birthDigits), survival: digitSet(survivalDigits)

preset = (name, rulestring) ->
  parsed = parse rulestring
  name: name, rulestring: rulestring, birth: parsed.birth, survival: parsed.survival

rulePresets =
  conway: preset "conway", "B3/S23"
  ant_colony: preset "ant_colony", "B3/S234"

fromRulestring = (rulestring) ->
  preset "custom", rulestring

tryFromRulestring = (rulestring) ->
  ok, rule = pcall fromRulestring, rulestring
  rule if ok

get = (name) ->
  rulePresets[name] or rulePresets[defaultRule]

list = ->
  names = [name for name in pairs rulePresets]
  table.sort names
  names

return {
  parse: parse, fromRulestring: fromRulestring, tryFromRulestring: tryFromRulestring
  get: get, list: list
}
