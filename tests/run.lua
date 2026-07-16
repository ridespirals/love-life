#!/usr/bin/env lua

package.path = table.concat({
  "./?.lua",
  "./?/init.lua",
  package.path,
}, ";")

local specs = {
  "tests/grid_spec.lua",
  "tests/layout_spec.lua",
  "tests/patterns_spec.lua",
  "tests/playback_spec.lua",
  "tests/rle_spec.lua",
  "tests/rules_spec.lua",
  "tests/step_animation_spec.lua",
  "tests/pane_spec.lua",
  "tests/phase2_spec.lua",
  "tests/statusbar_spec.lua",
  "tests/themes_spec.lua",
  "tests/userdata_spec.lua",
  "tests/color_spec.lua",
  "tests/board_spec.lua",
  "tests/phase4_spec.lua",
  "tests/phase5_spec.lua",
  "tests/text_field_spec.lua",
  "tests/button_fx_spec.lua",
  "tests/camera_spec.lua",
  "tests/toolbar_spec.lua",
}

local passed = 0
local failed = 0

for _, specPath in ipairs(specs) do
  local ok, err = pcall(dofile, specPath)
  if ok then
    passed = passed + 1
    print(string.format("ok %s", specPath))
  else
    failed = failed + 1
    print(string.format("FAIL %s", specPath))
    print(err)
  end
end

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
  os.exit(1)
end
