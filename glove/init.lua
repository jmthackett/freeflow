local love = require "love"
local colors = require "glove/colors"
require "glove/string-extensions"

local focusedWidget = nil
local g = love.graphics

local utilities = { "colors", "fonts", "fun" }

local widgets = {
  "Button",
  "Checkbox",
  "FPS",
  "HStack",
  "Image",
  "Input",
  "RadioButtons",
  "Select",
  "Spacer",
  "Tabs",
  "Text",
  "Toggle",
  "VStack",
  "ZStack"
}

Glove = {
  clickables = {},

  getAvailableHeight = function()
    return g.getHeight() - Glove.margin * 2
  end,

  getAvailableWidth = function()
    return g.getWidth() - Glove.margin * 2
  end,

  hoverColor = colors.green,

  margin = 20, -- inside window

  isFocused = function(widget)
    return widget == focusedWidget
  end,

  mousePressed = function(x, y, button)
    if button ~= 1 then return end
    for _, widget in ipairs(Glove.clickables) do
      if widget.visible then widget:handleClick(x, y) end
    end
  end,

  setFocus = function(widget)
    if focusedWidget and focusedWidget.removeFocus then
      focusedWidget:removeFocus()
    end
    focusedWidget = widget
  end
}

for _, module in ipairs(utilities) do
  Glove[module] = require("glove/" .. module)
end

for _, module in ipairs(widgets) do
  Glove[module] = require("glove/widgets/" .. module)
end

function love.mousepressed(x, y, button)
  Glove.mousePressed(x, y, button)
end
