local function hexToColor(hex)
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  return { r, g, b }
end

local function withBackground(theme)
  if not theme.background then
    theme.background = { theme.dead[1], theme.dead[2], theme.dead[3] }
  end
  return theme
end

local themes = {
  classic = withBackground({
    name = "classic",
    alive = hexToColor("#FFFFFF"),
    dead = hexToColor("#000000"),
    grid = hexToColor("#808080"),
    background = hexToColor("#000000"),
  }),
  zenburn = withBackground({
    name = "zenburn",
    alive = hexToColor("#DCDCCC"),
    dead = hexToColor("#4D4D4D"),
    grid = hexToColor("#3F3F3F"),
  }),
  solarized = withBackground({
    name = "solarized",
    alive = hexToColor("#fdf6e3"),
    dead = hexToColor("#002b36"),
    grid = hexToColor("#073642"),
  }),
}

local defaultTheme = "classic"

local M = {}

function M.get(name)
  return themes[name] or themes[defaultTheme]
end

function M.list()
  local names = {}
  for name in pairs(themes) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return M
