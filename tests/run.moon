#!/usr/bin/env lua

package.path = table.concat {
  "./?.lua",
  "./?/init.lua",
  package.path,
}, ";"

specs = {
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
}

passed = 0
failed = 0

for _, specPath in ipairs specs
  ok, err = pcall dofile, specPath
  if ok
    passed += 1
    print "ok #{specPath}"
  else
    failed += 1
    print "FAIL #{specPath}"
    print err

print "\n#{passed} passed, #{failed} failed"
os.exit 1 if failed > 0
