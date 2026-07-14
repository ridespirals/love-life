local config = require("src.config")
local color = require("src.color")

local function withBackground(theme)
  if not theme.background then
    theme.background = color.copy(theme.dead)
  end
  return theme
end

local function theme(name, alive, dead, grid, accent)
  local built = {
    name = name,
    alive = color.fromHex(alive),
    dead = color.fromHex(dead),
    grid = color.fromHex(grid or dead),
  }
  if accent then
    built.accent = color.fromHex(accent)
  end
  return withBackground(built)
end

-- alive/dead/grid from Normal fg/bg and structural vim groups;
-- accent from a signature syntax hue (String, Function, Keyword, etc.).
-- Hex literals here are define-time only; runtime theme colors are LÖVE RGB 0–1.
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

local userThemes = {}

local M = {}

function M.toHex(c)
  return color.toHex(c)
end

function M.colorFromHex(hex)
  return color.fromHex(hex)
end

function M.colorsToHex(theme)
  local hex = {
    alive = color.toHex(theme.alive),
    dead = color.toHex(theme.dead),
    grid = color.toHex(theme.grid),
    background = color.toHex(theme.background),
  }
  if theme.accent then
    hex.accent = color.toHex(theme.accent)
  end
  return hex
end

function M.colorsToRgb(theme)
  local rgb = {
    alive = color.copy(theme.alive),
    dead = color.copy(theme.dead),
    grid = color.copy(theme.grid),
    background = color.copy(theme.background),
  }
  if theme.accent then
    rgb.accent = color.copy(theme.accent)
  end
  return rgb
end

function M.build(opts)
  local alive = color.normalize(opts.alive)
  local dead = color.normalize(opts.dead)
  local grid = color.normalize(opts.grid)
  local background = color.normalize(opts.background)
  if not alive or not dead or not grid or not background then
    error("invalid theme color", 2)
  end

  local built = {
    name = opts.name or "custom",
    alive = alive,
    dead = dead,
    grid = grid,
    background = background,
  }
  if opts.accent and opts.accent ~= "" then
    local accent = color.normalize(opts.accent)
    if not accent then
      error("invalid accent color", 2)
    end
    built.accent = accent
  end
  return withBackground(built)
end

function M.tryBuild(opts)
  local ok, built = pcall(M.build, opts)
  if ok then
    return built
  end
end

function M.isBuiltin(id)
  return themes[id] ~= nil
end

function M.isUser(id)
  return userThemes[id] ~= nil
end

function M.loadUser(userdata)
  userThemes = {}
  if not userdata then
    return
  end

  for _, id in ipairs(userdata.list("themes")) do
    if not themes[id] then
      local data = userdata.load("themes", id)
      if data then
        local built = M.tryBuild({
          name = id,
          alive = data.alive,
          dead = data.dead,
          grid = data.grid,
          background = data.background,
          accent = (data.accent ~= "" and data.accent) or nil,
        })
        if built then
          userThemes[id] = built
        end
      end
    end
  end
end

function M.get(name)
  return themes[name] or userThemes[name] or themes[defaultTheme]
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

  addSorted(themes)
  addSorted(userThemes)
  return names
end

function M.skipped()
  return skipped
end

function M.extrusionShadow(theme, face, alive)
  if theme.accent then
    return color.lerp(
      face,
      theme.accent,
      alive and config.accentBlendAlive or config.accentBlendDead
    )
  end
  return color.lerp(face, { 0, 0, 0 }, alive and 0.35 or 0.2)
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
