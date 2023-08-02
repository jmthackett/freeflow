local colors = require "glove/colors"
local fun = require "glove/fun"
local love = require "love"

local g = love.graphics

local defaultValue = "Select ..."
local padding = 4

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      local font = self.font
      g.setFont(font)

      local selectedValue = self.table[self.key]
      local selectedChoice = fun.find(self.choices, function(choice)
        return choice.value == selectedValue
      end)

      -- Draw the border.
      local over = self:isOver(0, love.mouse.getPosition())
      g.setColor(over and Glove.hoverColor or self.color)
      local width = self:getWidth()
      local height = self:getHeight()
      g.rectangle("line", x, y, width, height)

      -- Draw the currently selected value.
      g.setColor(self.color)
      local value = selectedChoice and selectedChoice.label or "Select ..."
      g.print(value, x + padding, y + padding)

      -- Draw the downward triangle.
      local fontHeight = font:getHeight()
      local triangleSize = fontHeight - 8
      local triangleX = x + width - 6 - triangleSize
      local triangleTop = y + 8
      local triangleBottom = triangleTop + triangleSize
      g.polygon(
        "fill",
        triangleX, triangleTop,
        triangleX + triangleSize, triangleTop,
        triangleX + triangleSize / 2, triangleBottom
      )
    end,

    -- This is needed in order to draw an opened select
    -- on top of widgets below it.
    drawLater = function(self, parentX, parentY)
      if Glove.isFocused(self) and self.open then
        local x = parentX + self.x
        local y = parentY + self.y
        local fontHeight = self.font:getHeight()
        local dy = fontHeight + padding * 2
        local width = self:getWidth()
        local height = self:getHeight()

        for _, choice in ipairs(self.choices) do
          y = y + dy
          g.setColor(colors.white)
          g.rectangle("fill", x, y, width, height)
          g.setColor(colors.black)
          g.print(choice.label, x + padding, y + padding)
        end
      end
    end,

    getHeight = function(self)
      local fontHeight = self.font:getHeight()
      return fontHeight + padding * 2
    end,

    getWidth = function(self)
      local fontHeight = self.font:getHeight()
      return self.maxWidth + padding * 3 + fontHeight
    end,

    handleClick = function(self, clickX, clickY)
      if self:isOver(0, clickX, clickY) then
        Glove.setFocus(self)
        self.open = not self.open
        return
      end

      local fontHeight = self.font:getHeight()
      local y = 0
      local dy = fontHeight + padding * 2
      for _, choice in ipairs(self.choices) do
        y = y + dy
        if self:isOver(y, clickX, clickY) then
          local value = choice.value
          local t = self.table
          local key = self.key
          t[key] = value
          self.onChange(t, key, value)
          self.open = false
          self.selectedLabel = choice.label
          return true -- captured click
        end
      end

      return false -- did not capture click
    end,

    isOver = function(self, y, mouseX, mouseY)
      local x = self.actualX
      local testY = self.actualY
      if not x or not testY then return false end

      y = y + testY

      local width = self:getWidth()
      local height = self:getHeight()
      return x <= mouseX and mouseX <= x + width and
          y <= mouseY and mouseY <= y + height
    end,

    removeFocus = function(self)
      self.open = false
    end
  }
}

--[[
This widget displays a dropdown list of options
and allows the user to select one.

The selected value is tied to value of a given key in a given table.

The parameters are:

- choices described by an array-like table containing
  tables with `label` and `value` keys
- table that holds its state
- key within the table that holds its state
- table of options

The supported options are:

- `color`: of the labels; defaults to white
- `font`: used for the labels
- `onChange`: optional function to be called when a choice is selected
--]]
local function Select(choices, t, key, options)
  assert(type(choices) == "table", "Select choices must be a table.")

  options = options or {}
  assert(type(options) == "table", "Select options must be a table.")

  local font = options.font or g.getFont()

  local instance = options
  instance.kind = "Select"
  instance.choices = choices
  instance.color = instance.color or colors.white
  instance.font = font
  instance.open = false
  instance.table = t
  instance.key = key
  instance.visible = true

  -- Find the widest choice label.
  instance.maxWidth = fun.max(choices, function(choice)
    return font:getWidth(choice.label)
  end)
  local defaultWidth = font:getWidth(defaultValue)
  if defaultWidth > instance.maxWidth then
    instance.maxWidth = defaultWidth
  end

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return Select
