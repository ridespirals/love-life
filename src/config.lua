local config = {
  -- Starting hints for conf.lua window size (also duplicated in conf.lua because
  -- fused builds cannot dofile inside .love); overridden at runtime by auto-fit.
  -- App startup pattern is defaultPattern below; patterns.lua uses "glider" as get() fallback only.
  rows = 40,
  cols = 60,
  tileSize = 24,
  activeTheme = "solarized",
  activeRule = "conway",
  defaultPattern = "lifeview",
  stepInterval = 0.10,
  statusBarHeight = 28,
  paneWidth = 360,
  paneHeight = 120,
  paneBackdropAlpha = 0.55,
  paneScreenMargin = 8,
  stepAnimEnabled = true,
  stepAnimPreviewSec = 0.08,
  stepAnimCommitSec = 0.12,
  previewDotScale = 0.15,
  previewDotMinPx = 4,
  tileDepthAlivePx = 3,
  tileDepthDeadPx = 0,
  -- Temporary theme review harness (vim import batch). Toggle with `c`; step with `[` / `]`.
  themeReviewAutoCycle = false,
  themeReviewCycleSec = 3,
}

return config
