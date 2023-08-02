local colors = require "glove/colors"
local love = require "love"

love.keyboard.setKeyRepeat(true)
local g = love.graphics
local lk = love.keyboard
local padding = 4

local inputCursor, inputKey, inputTable

local mt = {
  __index = {
    color = colors.white,

    draw = function(self, parentX, parentY)
      if self.x and self.y then
        local x = parentX + self.x
        local y = parentY + self.y
        self.actualX = x
        self.actualY = y

        local over = self:isOver(love.mouse.getPosition())
        g.setColor(over and Glove.hoverColor or self.color)
        g.rectangle("line", x, y, self:getWidth(), self:getHeight())

        -- Get current value.
        local t = self.table
        local key = self.key
        local value = t[key] or ""

        -- Find substring of value that fits in width.
        local font = self.font
        local limit = self.width - padding * 2
        local i = 1
        local substr
        local substrWidth
        while true do
          substr = value:sub(i, #value)
          substrWidth = font:getWidth(substr)
          if substrWidth <= limit then break end
          i = i + 1
        end
        -- local truncated = i > 1

        x = x + padding
        y = y + padding

        g.setColor(self.color)
        g.setFont(font)
        g.print(substr, x, y)

        if Glove.isFocused(self) then
          local c = inputCursor
          if c then
            -- Draw vertical cursor line.
            local height = font:getHeight()
            local cursorPosition = math.min(c - i + 1, #substr)
            local cursorX = x + font:getWidth(substr:sub(1, cursorPosition))
            g.line(cursorX, y, cursorX, y + height)
          end
        end
      end
    end,

    getHeight = function(self)
      return self.font:getHeight() + padding * 2
    end,

    getWidth = function(self)
      return self.width
    end,

    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        Glove.setFocus(self)

        -- Enable keyboard.
        -- TODO: Is this needed? Maybe only on mobile devices.
        love.keyboard.setTextInput(
          true,
          self.actualX, self.actualY,
          self:getWidth(), self:getHeight()
        )

        local t = self.table
        local key = self.key
        local value = t[key] or ""
        inputTable = t
        inputKey = key
        inputCursor = #value
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
This widget allows the user to enter text.
The text automatically scrolls horizontally
when it exceeds the specified width.
The cursor can be positioned using the left and right arrow keys.
The character to the left of the cursor can be deleted
by pressing the delete key.

The text is tied to value of a given key in a given table.

Current the cursor cannot be positioned by clicking
and the entered text cannot be selected.

The parameters are:

- table that holds its state
- key within the table that holds its state
- table of options

The supported options are:

- `color`: of the border and text; defaults to white
- `font`: used for the text
- `width`: of the widget
--]]
local function Input(t, key, options)
  local to = type(options)
  assert(to == "table" or to == "nil", "Input options must be a table.")

  local width = options.width
  assert(type(width) == "number", "Input requires a number width option.")

  local instance = options or {}

  instance.kind = "Input"
  local font = instance.font or g.getFont()
  instance.font = font
  instance.table = t
  instance.key = key
  instance.visible = true

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

function love.keypressed(keyPressed)
  local t = inputTable
  local key = inputKey
  local c = inputCursor
  if not t or not key then return end

  local value = t[key]

  if keyPressed == "backspace" then
    if c > 0 then
      t[key] = value:sub(1, c - 1) .. value:sub(c + 1, #value)
      inputCursor = c - 1
    end
  elseif keyPressed == "left" then
    if c > 0 then inputCursor = c - 1 end
  elseif keyPressed == "right" then
    if c < #value then inputCursor = c + 1 end
  else
    if keyPressed == "space" then keyPressed = " " end

    -- Only process printable ASCII characters.
    if #keyPressed == 1 then
      local head = c == 0 and "" or value:sub(1, c)
      local tail = value:sub(c + 1, #value)
      local shift = lk.isDown("lshift") or lk.isDown("rshift")
      local char = shift and key:upper() or keyPressed
      t[key] = head .. char .. tail
      inputCursor = c + 1
    end
  end
end

return Input
