local color = require("src.color")

local M = {}

local DIALOG_W = 340
local DIALOG_H = 300
local PAD = 12
local SV_SIZE = 180
local SLIDER_W = 18
local GAP = 12
local BTN_W = 72
local BTN_H = 24
local PREVIEW_H = 28
local SV_RES = 64
local SLIDER_RES = 128

local function setColor(c, alpha)
  love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end

local function contains(rect, x, y)
  return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function rebuildSvImage(state)
  local imageData = love.image.newImageData(SV_RES, SV_RES)
  for y = 0, SV_RES - 1 do
    local v = 1 - (y / (SV_RES - 1))
    for x = 0, SV_RES - 1 do
      local s = x / (SV_RES - 1)
      local rgb = color.hsvToRgb(state.h, s, v)
      imageData:setPixel(x, y, rgb[1], rgb[2], rgb[3], 1)
    end
  end
  if state.svImage then
    state.svImage:release()
  end
  state.svImage = love.graphics.newImage(imageData)
  state.svImage:setFilter("linear", "linear")
end

local function rebuildHueImage(state)
  local imageData = love.image.newImageData(1, SLIDER_RES)
  for y = 0, SLIDER_RES - 1 do
    local h = y / (SLIDER_RES - 1)
    local rgb = color.hsvToRgb(h, 1, 1)
    imageData:setPixel(0, y, rgb[1], rgb[2], rgb[3], 1)
  end
  if state.hueImage then
    state.hueImage:release()
  end
  state.hueImage = love.graphics.newImage(imageData)
  state.hueImage:setFilter("linear", "linear")
end

-- Vertical value strip: top = V 100%, bottom = V 0% at current hue/saturation.
local function rebuildValueImage(state)
  local imageData = love.image.newImageData(1, SLIDER_RES)
  for y = 0, SLIDER_RES - 1 do
    local v = 1 - (y / (SLIDER_RES - 1))
    local rgb = color.hsvToRgb(state.h, state.s, v)
    imageData:setPixel(0, y, rgb[1], rgb[2], rgb[3], 1)
  end
  if state.valueImage then
    state.valueImage:release()
  end
  state.valueImage = love.graphics.newImage(imageData)
  state.valueImage:setFilter("linear", "linear")
end

local function layout(_state)
  local ww, wh = love.graphics.getDimensions()
  local x = math.floor((ww - DIALOG_W) / 2)
  local y = math.floor((wh - DIALOG_H) / 2)
  local sv = {
    x = x + PAD,
    y = y + PAD + 22,
    w = SV_SIZE,
    h = SV_SIZE,
  }
  local hue = {
    x = sv.x + sv.w + GAP,
    y = sv.y,
    w = SLIDER_W,
    h = SV_SIZE,
  }
  local value = {
    x = hue.x + hue.w + GAP,
    y = sv.y,
    w = SLIDER_W,
    h = SV_SIZE,
  }
  local preview = {
    x = x + PAD,
    y = sv.y + sv.h + GAP,
    w = DIALOG_W - PAD * 2,
    h = PREVIEW_H,
  }
  local cancel = {
    x = x + DIALOG_W - PAD - BTN_W * 2 - GAP,
    y = y + DIALOG_H - PAD - BTN_H,
    w = BTN_W,
    h = BTN_H,
    label = "Cancel",
  }
  local ok = {
    x = x + DIALOG_W - PAD - BTN_W,
    y = cancel.y,
    w = BTN_W,
    h = BTN_H,
    label = "OK",
  }
  return {
    x = x,
    y = y,
    w = DIALOG_W,
    h = DIALOG_H,
    sv = sv,
    hue = hue,
    value = value,
    preview = preview,
    cancel = cancel,
    ok = ok,
  }
end

local function currentRgb(state)
  return color.hsvToRgb(state.h, state.s, state.v)
end

local function setFromPointerSv(state, ui, mx, my)
  local t = (mx - ui.sv.x) / ui.sv.w
  local u = (my - ui.sv.y) / ui.sv.h
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  if u < 0 then u = 0 elseif u > 1 then u = 1 end
  state.s = t
  state.v = 1 - u
  rebuildValueImage(state)
end

local function setFromPointerHue(state, ui, my)
  local t = (my - ui.hue.y) / ui.hue.h
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  state.h = t
  rebuildSvImage(state)
  rebuildValueImage(state)
end

local function setFromPointerValue(state, ui, my)
  local t = (my - ui.value.y) / ui.value.h
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  state.v = 1 - t
end

function M.create()
  return {
    open = false,
    h = 0,
    s = 1,
    v = 1,
    drag = nil,
    svImage = nil,
    hueImage = nil,
    valueImage = nil,
    field = nil,
    result = nil,
  }
end

function M.isOpen(state)
  return state.open == true
end

function M.open(state, initialColor, field)
  local rgb = color.normalize(initialColor) or color.rgb(1, 0, 0)
  state.h, state.s, state.v = color.rgbToHsv(rgb)
  -- Keep last hue when picking near-grey (s≈0), otherwise square jumps to red.
  if state.s < 1e-4 then
    state.h = state.h or 0
  end
  state.field = field
  state.result = nil
  state.drag = nil
  state.open = true
  rebuildSvImage(state)
  if not state.hueImage then
    rebuildHueImage(state)
  end
  rebuildValueImage(state)
end

function M.close(state)
  state.open = false
  state.drag = nil
  state.field = nil
end

function M.takeResult(state)
  local result = state.result
  state.result = nil
  return result
end

function M.draw(state, theme, config)
  if not state.open then
    return
  end

  local ww, wh = love.graphics.getDimensions()
  local alpha = (config and config.paneBackdropAlpha) or 0.55
  love.graphics.setColor(0, 0, 0, alpha)
  love.graphics.rectangle("fill", 0, 0, ww, wh)

  local ui = layout(state)
  setColor(theme.dead, 1)
  love.graphics.rectangle("fill", ui.x, ui.y, ui.w, ui.h)
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", ui.x + 0.5, ui.y + 0.5, ui.w, ui.h)

  setColor(theme.alive, 1)
  love.graphics.print("Color", ui.x + PAD, ui.y + PAD)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(state.svImage, ui.sv.x, ui.sv.y, 0, ui.sv.w / SV_RES, ui.sv.h / SV_RES)
  love.graphics.draw(state.hueImage, ui.hue.x, ui.hue.y, 0, ui.hue.w, ui.hue.h / SLIDER_RES)
  love.graphics.draw(state.valueImage, ui.value.x, ui.value.y, 0, ui.value.w, ui.value.h / SLIDER_RES)

  setColor(theme.grid, 1)
  love.graphics.rectangle("line", ui.sv.x + 0.5, ui.sv.y + 0.5, ui.sv.w, ui.sv.h)
  love.graphics.rectangle("line", ui.hue.x + 0.5, ui.hue.y + 0.5, ui.hue.w, ui.hue.h)
  love.graphics.rectangle("line", ui.value.x + 0.5, ui.value.y + 0.5, ui.value.w, ui.value.h)

  local knx = ui.sv.x + state.s * ui.sv.w
  local kny = ui.sv.y + (1 - state.v) * ui.sv.h
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle("line", knx, kny, 6)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.circle("line", knx, kny, 5)

  local hy = ui.hue.y + state.h * ui.hue.h
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", ui.hue.x - 2, hy - 3, ui.hue.w + 4, 6)

  local vy = ui.value.y + (1 - state.v) * ui.value.h
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", ui.value.x - 2, vy - 3, ui.value.w + 4, 6)

  local rgb = currentRgb(state)
  setColor(rgb, 1)
  love.graphics.rectangle("fill", ui.preview.x, ui.preview.y, ui.preview.w, ui.preview.h)
  setColor(theme.grid, 1)
  love.graphics.rectangle("line", ui.preview.x + 0.5, ui.preview.y + 0.5, ui.preview.w, ui.preview.h)
  setColor(theme.alive, 1)
  love.graphics.print(color.toHex(rgb), ui.preview.x + 6, ui.preview.y + 6)

  for _, btn in ipairs({ ui.cancel, ui.ok }) do
    setColor(theme.grid, 1)
    love.graphics.rectangle("line", btn.x + 0.5, btn.y + 0.5, btn.w, btn.h)
    setColor(theme.alive, 1)
    love.graphics.printf(btn.label, btn.x, btn.y + 4, btn.w, "center")
  end
end

function M.mousepressed(state, x, y)
  if not state.open then
    return false
  end
  local ui = layout(state)
  if contains(ui.ok, x, y) then
    state.result = {
      color = currentRgb(state),
      field = state.field,
      confirmed = true,
    }
    M.close(state)
    return true
  end
  if contains(ui.cancel, x, y) then
    state.result = { confirmed = false }
    M.close(state)
    return true
  end
  if contains(ui.sv, x, y) then
    state.drag = "sv"
    setFromPointerSv(state, ui, x, y)
    return true
  end
  if contains(ui.hue, x, y) then
    state.drag = "hue"
    setFromPointerHue(state, ui, y)
    return true
  end
  if contains(ui.value, x, y) then
    state.drag = "value"
    setFromPointerValue(state, ui, y)
    return true
  end
  -- Click outside dialog = cancel
  if not contains(ui, x, y) then
    state.result = { confirmed = false }
    M.close(state)
    return true
  end
  return true
end

function M.mousemoved(state, x, y)
  if not state.open or not state.drag then
    return false
  end
  local ui = layout(state)
  if state.drag == "sv" then
    setFromPointerSv(state, ui, x, y)
  elseif state.drag == "hue" then
    setFromPointerHue(state, ui, y)
  elseif state.drag == "value" then
    setFromPointerValue(state, ui, y)
  end
  return true
end

function M.mousereleased(state)
  if not state.open then
    return false
  end
  state.drag = nil
  return true
end

function M.keypressed(state, key)
  if not state.open then
    return false
  end
  if key == "escape" then
    state.result = { confirmed = false }
    M.close(state)
    return true
  end
  if key == "return" or key == "kpenter" then
    state.result = {
      color = currentRgb(state),
      field = state.field,
      confirmed = true,
    }
    M.close(state)
    return true
  end
  return true
end

return M
