local assert = require("tests.assert")
local color = require("src.color")
local test = require("tests.spec_helper").test

test("rgb clamps to 0-1", function()
  local c = color.rgb(-1, 0.5, 2)
  assert.equal(c[1], 0)
  assert.equal(c[2], 0.5)
  assert.equal(c[3], 1)
end)

test("fromHex and toHex round-trip", function()
  local c = color.fromHex("#ff8000")
  assert.equal(color.toHex(c), "#ff8000")
  assert.equal(color.toHex(color.fromHex("0xf00")), "#ff0000")
end)

test("normalize accepts hex and float tables", function()
  assert.equal(color.toHex(color.normalize("#00ff00")), "#00ff00")
  assert.equal(color.toHex(color.normalize({ 0, 1, 0 })), "#00ff00")
  assert.equal(color.toHex(color.normalize({ 0, 255, 0 })), "#00ff00")
end)

test("hsv full saturation red and mid values convert", function()
  local red = color.hsvToRgb(0, 1, 1)
  assert.equal(color.toHex(red), "#ff0000")
  local h, s, v = color.rgbToHsv(red)
  assert.equal(h, 0)
  assert.equal(s, 1)
  assert.equal(v, 1)
end)

test("hsv grey has zero saturation", function()
  local h, s, v = color.rgbToHsv(color.rgb(0.4, 0.4, 0.4))
  assert.equal(s, 0)
  assert.equal(v, 0.4)
  assert.isTrue(h == h) -- not nan
end)
