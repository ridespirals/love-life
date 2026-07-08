#!/usr/bin/env lua

package.path = table.concat({
  "./?.lua",
  "./?/init.lua",
  package.path,
}, ";")

local specs = {
  "tests/grid_spec.lua",
  "tests/rules_spec.lua",
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
