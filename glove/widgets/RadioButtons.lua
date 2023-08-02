local colors = require "glove/colors"
local love = require "love"

local g = love.graphics

local size = 24
local circleRadius = size / 2

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      g.setColor(self.color)
      local font = self.font
      g.setFont(font)
      local height = font:getHeight()
      local dy = (size - height) / 2

      local spacing = circleRadius
      local selectedValue = self.table[self.key]

      if self.vertical then
        local circleCenterX = x + circleRadius
        for _, choice in ipairs(self.choices) do
          local circleCenterY = y + circleRadius
          local labelWidth = font:getWidth(choice.label)
          local choiceWidth = size + spacing + labelWidth
          local over = self:isOver(x, y, choiceWidth, love.mouse.getPosition())
          g.setColor(over and Glove.hoverColor or self.color)
          g.circle("line", circleCenterX, circleCenterY, circleRadius)

          g.setColor(self.color)
          if choice.value == selectedValue then
            g.circle("fill", circleCenterX, circleCenterY, circleRadius - 2)
          end
          g.print(choice.label, x + size + spacing, y + dy)
          y = y + size + spacing
        end
      else -- horizontal
        local circleCenterY = y + circleRadius
        for _, choice in ipairs(self.choices) do
          local circleCenterX = x + circleRadius
          local labelWidth = font:getWidth(choice.label)
          local choiceWidth = size + spacing + labelWidth
          local over = self:isOver(x, y, choiceWidth, love.mouse.getPosition())
          g.setColor(over and Glove.hoverColor or self.color)
          g.circle("line", circleCenterX, circleCenterY, circleRadius)

          g.setColor(self.color)
          if choice.value == selectedValue then
            g.circle("fill", circleCenterX, circleCenterY, circleRadius - 2)
          end
          x = x + size + spacing
          g.print(choice.label, x, y + dy)
          x = x + font:getWidth(choice.label) + spacing * 2
        end
      end
    end,

    getHeight = function(self)
      return self.height
    end,

    getWidth = function(self)
      return self.width
    end,

    handleClick = function(self, clickX, clickY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return end

      local font = self.font
      local spacing = circleRadius

      if self.vertical then
        for _, choice in ipairs(self.choices) do
          local labelWidth = font:getWidth(choice.label)
          local choiceWidth = size + spacing + labelWidth
          if self:isOver(x, y, choiceWidth, clickX, clickY) then
            Glove.setFocus(self)
            local value = choice.value
            local t = self.table
            local key = self.key
            t[key] = value
            if self.onChange then self.onChange(t, key, value) end
            return true -- captured click
          end
          y = y + size + spacing
        end
      else -- horizontal
        for _, choice in ipairs(self.choices) do
          local labelWidth = font:getWidth(choice.label)
          local choiceWidth = size + spacing + labelWidth
          if self:isOver(x, y, choiceWidth, clickX, clickY) then
            Glove.setFocus(self)
            local value = choice.value
            local t = self.table
            local key = self.key
            t[key] = value
            if self.onChange then self.onChange(t, key, value) end
            return true -- captured click
          end
          x = x + size + spacing
          x = x + labelWidth + spacing * 2
        end
      end

      return false -- did not capture click
    end,

    isOver = function(self, x, y, width, mouseX, mouseY)
      if not x or not y then return false end

      return x <= mouseX and mouseX <= x + width and
          y <= mouseY and mouseY <= y + size
    end
  }
}

--[[
This widget allows the user to select one radiobutton from a set.

The selected value is tied to value of a given key in a given table.

The parameters are:

- choices described by an array-like table containing
  tables with `label` and `value` keys
- table that holds its state
- key within the table that holds its state
- table of options

The supported options are:

- `color`: of the radiobuttons and their labels; defaults to white
- `font`: used for the labels
- `onChange`: optional function to be called when a choice is selected
- `vertical`: boolean indicating whether the radiobuttons
  should be arranged vertically; defaults to false
--]]
local function RadioButtons(choices, t, key, options)
  assert(type(choices) == "table", "RadioButtons choices must be a table.")

  options = options or {}
  assert(type(options) == "table", "RadioButtons options must be a table.")

  local font = options.font or g.getFont()

  local instance = options
  instance.kind = "RadioButtons"
  instance.choices = choices
  instance.color = instance.color or colors.white
  instance.font = font
  instance.table = t
  instance.key = key
  instance.visible = true

  local fontHeight = font:getHeight()
  local height = 0
  local width = 0

  local spacing = circleRadius
  if instance.vertical then
    height = #choices * (size + spacing) - spacing
    for _, choice in ipairs(choices) do
      local w = size + spacing + font:getWidth(choice.label)
      if w > width then width = w end
    end
  else
    local height = fontHeight
    local width = 0
    for _, choice in ipairs(choices) do
      width = width + size + spacing + font:getWidth(choice.label) + spacing * 2
    end
    width = width - spacing * 2
  end

  instance.width = width
  instance.height = height

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return RadioButtons
