local love = require "love"

local g = love.graphics

local padding = 2
local size = 24
local halfSize = size / 2
local width = size * 1.8

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      local over = self:isOver(love.mouse.getPosition())
      g.setColor(over and Glove.hoverColor or self.color)
      g.setFont(self.font)
      g.rectangle("line", x, y, width, size, halfSize, halfSize)

      g.setColor(self.color)

      local checked = self.table[self.key]
      local circleRadius = size / 2 - padding
      local circleX = checked and x + width - padding - circleRadius or x + padding + circleRadius
      local circleY = y + padding + circleRadius
      g.circle("fill", circleX, circleY, circleRadius)
    end,

    getHeight = function()
      return size
    end,

    getWidth = function()
      return width
    end,

    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        Glove.setFocus(self)
        local t = self.table
        local key = self.key
        local checked = t[key]
        t[key] = not checked
        if self.onChange then
          self.onChange(t, key, not checked)
        end
      end
      return clicked
    end,

    isOver = function(self, mouseX, mouseY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return false end

      return x <= mouseX and mouseX <= x + width and
          y <= mouseY and mouseY <= y + size
    end
  }
}

--[[
This widget ties a toggle state to a boolean value in a table.

The parameters are:

- table that holds its state
- key within the table that holds its state
- table of options

The supported options are:

- `color`: of the toggle; defaults to white
- `onChange`: optional function called when the checkbox is clicked
--]]
local function Toggle(t, key, options)
  options = options or {}
  assert(type(options) == "table", "Toggle options must be a table.")

  local font = options.font or g.getFont()

  local instance = options
  instance.kind = "Toggle"
  instance.color = instance.color or Glove.colors.white
  instance.font = font
  instance.table = t
  instance.key = key
  instance.visible = true

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return Toggle
