local assert = require("tests.assert")
local tooltip = require("src.ui.tooltip")
local test = require("tests.spec_helper").test
local withLoveGraphicsMock = require("tests.spec_helper").withLoveGraphicsMock

test("layout places tooltip near cursor without covering avoid rect", function()
  withLoveGraphicsMock({ width = 800, height = 600 }, function()
    _G.love.graphics.getFont = function()
      return {
        getWidth = function(_, text)
          return #text * 7
        end,
        getHeight = function()
          return 12
        end,
      }
    end

    local avoid = { x = 10, y = 10, w = 32, h = 32 }
    local box = tooltip.layout("Mouse mode: pan screen", 20, 20, avoid, 800, 600)
    assert.isTrue(box.y >= avoid.y + avoid.h)
    assert.isTrue(box.w > 0)
    assert.isTrue(box.h > 0)
  end)
end)

test("layout supports multiline tooltips", function()
  withLoveGraphicsMock({ width = 800, height = 600 }, function()
    _G.love.graphics.getFont = function()
      return {
        getWidth = function(_, text)
          return #text * 7
        end,
        getHeight = function()
          return 12
        end,
      }
    end

    local single = tooltip.layout("Mouse mode: draw", 40, 40, nil, 800, 600)
    local multi = tooltip.layout(
      "Mouse mode: draw\nLeft-click: Living cell. Right-click: Dead cell.",
      40,
      40,
      nil,
      800,
      600
    )
    assert.equal(#multi.lines, 2)
    assert.isTrue(multi.h > single.h)
    assert.isTrue(multi.w > single.w)
  end)
end)
