config = require "src.config"

hexToColor = (hex) ->
  hex = hex\gsub "#", ""
  r = tonumber(hex\sub(1, 2), 16) / 255
  g = tonumber(hex\sub(3, 4), 16) / 255
  b = tonumber(hex\sub(5, 6), 16) / 255
  { r, g, b }

lerpColor = (color, target, amount) ->
  {
    color[1] + (target[1] - color[1]) * amount,
    color[2] + (target[2] - color[2]) * amount,
    color[3] + (target[3] - color[3]) * amount,
  }

colorToHex = (color) ->
  byte = (channel) -> string.format "%02x", math.floor(channel * 255 + 0.5)
  "##{byte color[1]}#{byte color[2]}#{byte color[3]}"

withBackground = (theme) ->
  unless theme.background
    theme.background = { theme.dead[1], theme.dead[2], theme.dead[3] }
  theme

theme = (name, alive, dead, gridColor, accent) ->
  built =
    name: name
    alive: hexToColor(alive)
    dead: hexToColor(dead)
    grid: hexToColor(gridColor or dead)
  built.accent = hexToColor(accent) if accent
  withBackground built

themes =
  classic: theme "classic", "#FFFFFF", "#000000", "#808080", "#00AAAA"
  zenburn: theme "zenburn", "#DCDCCC", "#4D4D4D", "#3F3F3F", "#8CD0D3"
  solarized: theme "solarized", "#fdf6e3", "#002b36", "#073642", "#2AA198"
  monokai: theme "monokai", "#F8F8F2", "#272822", "#3C3D37", "#A6E22E"
  molokai: theme "molokai", "#F8F8F2", "#1B1D1E", "#232526", "#FD971F"
  gruvbox: theme "gruvbox", "#EBDBB2", "#282828", "#3C3836", "#B8BB26"
  dracula: theme "dracula", "#F8F8F2", "#282A36", "#44475A", "#FF79C6"
  nord: theme "nord", "#D8DEE9", "#2E3440", "#3B4252", "#88C0D0"
  onedark: theme "onedark", "#ABB2BF", "#282C34", "#4B5263", "#98C379"
  tomorrow_night: theme "tomorrow_night", "#C5C8C6", "#1D1F21", "#282A2E", "#B5BD68"
  tomorrow_night_bright: theme "tomorrow_night_bright", "#EAEAEA", "#000000", "#2A2A2A", "#E7C547"
  oceanic_next: theme "oceanic_next", "#C0C5CE", "#1B2B34", "#343D46", "#F99157"
  jellybeans: theme "jellybeans", "#E8E8D3", "#151515", "#1C1C1C", "#FFB964"
  apprentice: theme "apprentice", "#BCBCBC", "#262626", "#1C1C1C", "#AF875F"
  material: theme "material", "#CDD3DE", "#263238", "#36474E", "#82AAFF"
  railscasts: theme "railscasts", "#E4E4E4", "#121212", "#1C1C1C", "#A5C261"
  wombat: theme "wombat", "#F6F3E8", "#242424", "#2D2D2D", "#E69F00"
  afterglow: theme "afterglow", "#D6D6D6", "#1E1E1E", "#393939", "#E87D3E"
  synthwave: theme "synthwave", "#BFB8CC", "#312E39", "#393642", "#943B4E"
  lucius: theme "lucius", "#000000", "#F8F8F8", "#B0C0D0", "#288BD6"
  github: theme "github", "#000000", "#F8F8FF", "#ECECEC", "#0366D6"

skippedThemes = {
  { name: "ayu", reason: "multi-mode palette (dark/mirage/light) with runtime branches" },
  { name: "desert", reason: "uses named vim colors (White, grey20) not hex" },
  { name: "koehler", reason: "uses named vim colors (white, black) not hex" },
  { name: "badwolf", reason: "symbolic palette names resolved at runtime" },
  { name: "benokai", reason: "duplicate of monokai palette" },
}

defaultTheme = "classic"

toHex = (color) ->
  colorToHex color

colorFromHex = (hex) ->
  return unless hex and hex ~= "" and #hex >= 7
  ok, color = pcall hexToColor, hex
  color if ok

colorsToHex = (themeObj) ->
  hex =
    alive: colorToHex(themeObj.alive)
    dead: colorToHex(themeObj.dead)
    grid: colorToHex(themeObj.grid)
    background: colorToHex(themeObj.background)
  hex.accent = colorToHex(themeObj.accent) if themeObj.accent
  hex

build = (opts) ->
  built =
    name: opts.name or "custom"
    alive: hexToColor(opts.alive)
    dead: hexToColor(opts.dead)
    grid: hexToColor(opts.grid)
    background: hexToColor(opts.background)
  built.accent = hexToColor(opts.accent) if opts.accent
  withBackground built

tryBuild = (opts) ->
  ok, built = pcall build, opts
  built if ok

get = (name) ->
  themes[name] or themes[defaultTheme]

list = ->
  names = [n for n in pairs themes]
  table.sort names
  names

skipped = ->
  skippedThemes

extrusionShadow = (themeObj, face, alive) ->
  if themeObj.accent
    return lerpColor face, themeObj.accent, if alive then config.accentBlendAlive else config.accentBlendDead
  lerpColor face, { 0, 0, 0 }, if alive then 0.35 else 0.2

indexOf = (name) ->
  names = list!
  for i, entry in ipairs names
    return i if entry == name

next = (name) ->
  names = list!
  index = indexOf(name) or 0
  names[(index % #names) + 1]

prev = (name) ->
  names = list!
  index = indexOf(name) or 1
  names[((index - 2) % #names) + 1]

return {
  toHex: toHex, colorFromHex: colorFromHex, colorsToHex: colorsToHex
  build: build, tryBuild: tryBuild, get: get, list: list, skipped: skipped
  extrusionShadow: extrusionShadow, next: next, prev: prev
}
