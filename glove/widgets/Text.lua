local colors = require "glove/colors"
local love = require "love"

local g = love.graphics
local padding = 0

local mt = {
  __index = {
    color = colors.white,
    draw = function(self, parentX, parentY)
      g.setColor(self.color)
      if self.x and self.y then
        g.setFont(self.font)
        parentX = parentX or 0
        parentY = parentY or 0

        g.print(
          self:getText(),
          parentX + self.x + padding,
          parentY + self.y + padding
        )

        if self.debug then
          g.setColor(colors.red)
          g.rectangle(
            "line",
            parentX + self.x, parentY + self.y,
            self:getWidth(), self:getHeight()
          )
        end
      end
    end,

    getHeight = function(self)
      return self.font:getHeight() + padding * 2
    end,

    getText = function(self)
      local text = self.text
      local value
      if type(text) == "function" then
        value = text()
      else
        local t = self.table
        local key = self.key
        value = t and key and t[key] or self.text
      end
      return value
    end,

    getWidth = function(self)
      if self.width then return self.width end

      local value = self:getText()
      return self.font:getWidth(value) + padding * 2
    end
  }
}

--[[
This widget displays static or computed text.

The parameters are:

- text to display or a function that returns it
- table of options

The supported options are:

- `color`: of the text; defaults to white
- `font`: used for the text
- `table`: a table that holds the text to display
- `key`: a key within the table that holds the text to display
- `width`: used when key and table are specified
--]]
local function Text(text, options)
  local to = type(options)
  assert(to == "table" or to == "nil", "Text options must be a table.")

  if not text then
    error("Text requires text to display or a function")
  end

  local instance = options or {}
  instance.kind = "Text"
  local font = instance.font or g.getFont()
  instance.font = font
  instance.text = text
  setmetatable(instance, mt)
  return instance
end

return Text
