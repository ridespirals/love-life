local config = {
  -- Starting hints for conf.lua window size (also duplicated in conf.lua because
  -- fused builds cannot dofile inside .love); overridden at runtime by auto-fit.
  -- App startup pattern is defaultPattern below; patterns.lua uses "glider" as get() fallback only.
  rows = 40,
  cols = 60,
  tileSize = 12,
  activeTheme = "solarized",
  activeRule = "conway",
  defaultPattern = "lifeview",
  stepInterval = 0.10,
  statusBarHeight = 28,
  previewDotScale = 0.18,
  previewDotMinRadiusPx = 2,
  previewDotMaxRadiusPx = 8,
}

return config
