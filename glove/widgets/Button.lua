local colors = require "glove/colors"
local love = require "love"

local g = love.graphics
local padding = 10

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      local cornerRadius = padding
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      local width = self:getWidth()
      local height = self:getHeight()
      
      if self:isOver(love.mouse.getPosition()) then
        local op = 3 -- outline padding
        g.setColor(Glove.hoverColor)
        g.rectangle(
          "line",
          x - op, y - op,
          width + op * 2, height + op * 2,
          cornerRadius, cornerRadius
        )
      end

      g.setColor(self.buttonColor)
      g.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)

      g.setColor(self.labelColor)
      g.setFont(self.font)
      g.print(self.label, x + padding, y + padding)
    end,

    getHeight = function(self)
      local labelHeight = self.font:getHeight()
      return labelHeight + padding * 2
    end,

    getWidth = function(self)
      local labelWidth = self.font:getWidth(self.label)
      return labelWidth + padding * 2
    end,

    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        Glove.setFocus(self)
        self.onClick()
      end
      return clicked
    end,

    isOver = function(self, mouseX, mouseY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return false end

      local width = self:getWidth()
      local height = self:getHeight()
      return x <= mouseX and mouseX <= x + width and
          y <= mouseY and mouseY <= y + height
    end
  }
}

--[[
This widget is a clickable button.

The parameters are:

- text to display on the button
- table of options

The supported options are:

- `buttonColor`: background color of the button; defaults to white
- `font`: font used for the button label
- `labelColor`: color of the label; defaults to black
- `onClick`: function called when the button is clicked
--]]
local function Button(label, options)
  options = options or {}
  assert(type(options) == "table", "Button options must be a table.")

  local font = options.font or g.getFont()

  local instance = options
  instance.kind = "Button"
  instance.font = font
  instance.label = label
  instance.labelColor = instance.labelColor or colors.black
  instance.buttonColor = instance.buttonColor or colors.white
  instance.visible = true

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return Button
