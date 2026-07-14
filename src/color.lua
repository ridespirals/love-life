-- Canonical color format for LÖVE 11+: RGB(A) tables with channels in [0, 1].
-- Hex and HSV are interchange formats at UI/IO boundaries only.
local M = {}

local function clamp01(x)
  if x < 0 then
    return 0
  end
  if x > 1 then
    return 1
  end
  return x
end

function M.rgb(r, g, b, a)
  local color = { clamp01(r), clamp01(g), clamp01(b) }
  if a ~= nil then
    color[4] = clamp01(a)
  end
  return color
end

function M.copy(color)
  if not color then
    return nil
  end
  return M.rgb(color[1], color[2], color[3], color[4])
end

function M.equals(a, b, epsilon)
  if not a or not b then
    return a == b
  end
  epsilon = epsilon or 1e-5
  for i = 1, 3 do
    if math.abs((a[i] or 0) - (b[i] or 0)) > epsilon then
      return false
    end
  end
  return true
end

function M.fromBytes(r, g, b, a)
  if a ~= nil then
    return M.rgb(r / 255, g / 255, b / 255, a / 255)
  end
  return M.rgb(r / 255, g / 255, b / 255)
end

function M.toBytes(color)
  local function byte(channel)
    return math.floor(clamp01(channel) * 255 + 0.5)
  end
  return byte(color[1]), byte(color[2]), byte(color[3]), color[4] and byte(color[4]) or nil
end

function M.fromHex(hex)
  if type(hex) ~= "string" or hex == "" then
    return nil
  end
  hex = hex:gsub("^#", ""):gsub("^0[xX]", "")
  if #hex == 3 or #hex == 4 then
    local expanded = ""
    for i = 1, #hex do
      local ch = hex:sub(i, i)
      expanded = expanded .. ch .. ch
    end
    hex = expanded
  end
  if #hex ~= 6 and #hex ~= 8 then
    return nil
  end
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  if not r or not g or not b then
    return nil
  end
  if #hex == 8 then
    local a = tonumber(hex:sub(7, 8), 16)
    if not a then
      return nil
    end
    return M.fromBytes(r, g, b, a)
  end
  return M.fromBytes(r, g, b)
end

function M.toHex(color)
  if not color then
    return nil
  end
  local r, g, b, a = M.toBytes(color)
  if a ~= nil then
    return string.format("#%02x%02x%02x%02x", r, g, b, a)
  end
  return string.format("#%02x%02x%02x", r, g, b)
end

-- HSV ↔ RGB (channels 0–1). Based on love2d.org/wiki/HSV_color
function M.hsvToRgb(h, s, v)
  h = clamp01(h)
  s = clamp01(s)
  v = clamp01(v)
  if s <= 0 then
    return M.rgb(v, v, v)
  end
  h = h * 6
  local c = v * s
  local x = (1 - math.abs((h % 2) - 1)) * c
  local m = v - c
  local r, g, b = 0, 0, 0
  if h < 1 then
    r, g, b = c, x, 0
  elseif h < 2 then
    r, g, b = x, c, 0
  elseif h < 3 then
    r, g, b = 0, c, x
  elseif h < 4 then
    r, g, b = 0, x, c
  elseif h < 5 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end
  return M.rgb(r + m, g + m, b + m)
end

function M.rgbToHsv(color)
  local r, g, b = clamp01(color[1]), clamp01(color[2]), clamp01(color[3])
  local maxc = math.max(r, g, b)
  local minc = math.min(r, g, b)
  local v = maxc
  local d = maxc - minc
  local s = maxc == 0 and 0 or d / maxc
  local h = 0
  if d > 0 then
    if maxc == r then
      h = ((g - b) / d) % 6
    elseif maxc == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h / 6
    if h < 0 then
      h = h + 1
    end
  end
  return h, s, v
end

-- Accept LÖVE RGB table, hex string, or {r,g,b} bytes-like if any channel > 1.
function M.normalize(value)
  if type(value) == "string" then
    return M.fromHex(value)
  end
  if type(value) ~= "table" then
    return nil
  end
  local r, g, b = value[1], value[2], value[3]
  if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
    return nil
  end
  if r > 1 or g > 1 or b > 1 then
    return M.fromBytes(r, g, b, value[4])
  end
  return M.rgb(r, g, b, value[4])
end

function M.isColor(value)
  return M.normalize(value) ~= nil
end

function M.lerp(a, b, t)
  t = clamp01(t)
  local out = {
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
    a[3] + (b[3] - a[3]) * t,
  }
  if a[4] or b[4] then
    out[4] = (a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t
  end
  return out
end

return M
