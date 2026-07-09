local config = require("src.config")

local function hexToColor(hex)
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  return { r, g, b }
end

local function lerpColor(color, target, amount)
  return {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }
end

local function colorToHex(color)
  local function byte(channel)
    return string.format("%02x", math.floor(channel * 255 + 0.5))
  end
  return "#" .. byte(color[1]) .. byte(color[2]) .. byte(color[3])
end

local function withBackground(theme)
  if not theme.background then
    theme.background = { theme.dead[1], theme.dead[2], theme.dead[3] }
  end
  return theme
end

local function theme(name, alive, dead, grid, accent)
  local built = {
    name = name,
    alive = hexToColor(alive),
    dead = hexToColor(dead),
    grid = hexToColor(grid or dead),
  }
  if accent then
    built.accent = hexToColor(accent)
  end
  return withBackground(built)
end

-- alive/dead/grid from Normal fg/bg and structural vim groups;
-- accent from a signature syntax hue (String, Function, Keyword, etc.).
local themes = {
  classic = theme("classic", "#FFFFFF", "#000000", "#808080", "#00AAAA"),
  zenburn = theme("zenburn", "#DCDCCC", "#4D4D4D", "#3F3F3F", "#8CD0D3"),
  solarized = theme("solarized", "#fdf6e3", "#002b36", "#073642", "#2AA198"),

  monokai = theme("monokai", "#F8F8F2", "#272822", "#3C3D37", "#A6E22E"),
  molokai = theme("molokai", "#F8F8F2", "#1B1D1E", "#232526", "#FD971F"),
  gruvbox = theme("gruvbox", "#EBDBB2", "#282828", "#3C3836", "#B8BB26"),
  dracula = theme("dracula", "#F8F8F2", "#282A36", "#44475A", "#FF79C6"),
  nord = theme("nord", "#D8DEE9", "#2E3440", "#3B4252", "#88C0D0"),
  onedark = theme("onedark", "#ABB2BF", "#282C34", "#4B5263", "#98C379"),
  tomorrow_night = theme("tomorrow_night", "#C5C8C6", "#1D1F21", "#282A2E", "#B5BD68"),
  tomorrow_night_bright = theme("tomorrow_night_bright", "#EAEAEA", "#000000", "#2A2A2A", "#E7C547"),
  oceanic_next = theme("oceanic_next", "#C0C5CE", "#1B2B34", "#343D46", "#F99157"),
  jellybeans = theme("jellybeans", "#E8E8D3", "#151515", "#1C1C1C", "#FFB964"),
  apprentice = theme("apprentice", "#BCBCBC", "#262626", "#1C1C1C", "#AF875F"),
  material = theme("material", "#CDD3DE", "#263238", "#36474E", "#82AAFF"),
  railscasts = theme("railscasts", "#E4E4E4", "#121212", "#1C1C1C", "#A5C261"),
  wombat = theme("wombat", "#F6F3E8", "#242424", "#2D2D2D", "#E69F00"),
  afterglow = theme("afterglow", "#D6D6D6", "#1E1E1E", "#393939", "#E87D3E"),
  synthwave = theme("synthwave", "#BFB8CC", "#312E39", "#393642", "#943B4E"),

  lucius = theme("lucius", "#000000", "#F8F8F8", "#B0C0D0", "#288BD6"),
  github = theme("github", "#000000", "#F8F8FF", "#ECECEC", "#0366D6"),
}

local skipped = {
  { name = "ayu", reason = "multi-mode palette (dark/mirage/light) with runtime branches" },
  { name = "desert", reason = "uses named vim colors (White, grey20) not hex" },
  { name = "koehler", reason = "uses named vim colors (white, black) not hex" },
  { name = "badwolf", reason = "symbolic palette names resolved at runtime" },
  { name = "benokai", reason = "duplicate of monokai palette" },
}

local defaultTheme = "classic"

local M = {}

function M.toHex(color)
  return colorToHex(color)
end

function M.colorsToHex(theme)
  local hex = {
    alive = colorToHex(theme.alive),
    dead = colorToHex(theme.dead),
    grid = colorToHex(theme.grid),
    background = colorToHex(theme.background),
  }
  if theme.accent then
    hex.accent = colorToHex(theme.accent)
  end
  return hex
end

function M.build(opts)
  local built = {
    name = opts.name or "custom",
    alive = hexToColor(opts.alive),
    dead = hexToColor(opts.dead),
    grid = hexToColor(opts.grid),
    background = hexToColor(opts.background),
  }
  if opts.accent then
    built.accent = hexToColor(opts.accent)
  end
  return withBackground(built)
end

function M.tryBuild(opts)
  local ok, built = pcall(M.build, opts)
  if ok then
    return built
  end
end

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

function M.skipped()
  return skipped
end

function M.extrusionShadow(theme, face, alive)
  if theme.accent then
    return lerpColor(
      face,
      theme.accent,
      alive and config.accentBlendAlive or config.accentBlendDead
    )
  end
  return lerpColor(face, { 0, 0, 0 }, alive and 0.35 or 0.2)
end

local function indexOf(name)
  local names = M.list()
  for i, entry in ipairs(names) do
    if entry == name then
      return i
    end
  end
end

function M.next(name)
  local names = M.list()
  local index = indexOf(name) or 0
  return names[(index % #names) + 1]
end

function M.prev(name)
  local names = M.list()
  local index = indexOf(name) or 1
  return names[((index - 2) % #names) + 1]
end

return M
