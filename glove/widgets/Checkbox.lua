local colors = require "glove/colors"
local love = require "love"

local g = love.graphics

local size = 24
local s2 = size * 0.2
local s4 = size * 0.4
local s6 = size * 0.6
local s8 = size * 0.8
local spacing = size * 0.4

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      local over = self:isOver(love.mouse.getPosition())
      g.setColor(over and Glove.hoverColor or self.color)
      g.rectangle("line", x, y, size, size)

      g.setColor(self.color)

      local checked = self.table[self.key]
      if checked then
        g.setLineWidth(4)
        g.line(x + s2, y + s6, x + s4, y + s8, x + s8, y + s2)
        g.setLineWidth(1)
      end

      local font = self.font
      g.setFont(font)
      local height = font:getHeight()
      local dy = (size - height) / 2
      g.print(self.label, x + size + spacing, y + dy)

      if self.debug then
        g.setColor(colors.red)
        g.rectangle("line", x, y, self:getWidth(), self:getHeight())
      end
    end,

    getHeight = function(self)
      return math.max(size, self.font:getHeight())
    end,

    getWidth = function(self)
      return size + spacing + self.font:getWidth(self.label)
    end,

    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        Glove.setFocus(self)
        local t = self.table
        local key = self.key
        local checked = t[key]
        t[key] = not checked
        if self.onChange then self.onChange(t, key, not checked) end
      end
      return clicked
    end,

    isOver = function(self, mouseX, mouseY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return false end

      local labelWidth = self.font:getWidth(self.label)
      return mouseX >= x and
          mouseX <= x + size + spacing + labelWidth and
          mouseY >= y and
          mouseY <= y + size
    end
  }
}

--[[
This widget ties a checkbox state to a boolean value in a table.

The parameters are:

- text to display after the checkbox
- table that holds its state
- key within the table that holds its state

The supported options are:

- `font`: used for the button label
- `color`: of the label and checkbox; defaults to white
- `onChange`: optional function called when the checkbox is clicked
--]]
local function Checkbox(label, t, key, options)
  options = options or {}
  assert(type(options) == "table", "Checkbox options must be a table.")

  local font = options.font or g.getFont()

  local instance = options
  instance.kind = "Checkbox"
  instance.color = instance.color or colors.white
  instance.font = font
  instance.label = label
  instance.table = t
  instance.key = key
  instance.visible = true

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return Checkbox
