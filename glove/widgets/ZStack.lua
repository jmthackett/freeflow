local fun = require "glove/fun"
local love = require "love"

local function layout(self)
  local align = self.align or "NW"
  local children = self.children
  local x = self.x or 0
  local y = self.y or 0

  -- Get width of widest child.
  local maxWidth = fun.max(
    children,
    function(child) return child:getWidth() or 0 end
  )
  self.maxWidth = maxWidth

  -- Get height of tallest child.
  local maxHeight = fun.max(
    children,
    function(child) return child:getHeight() or 0 end
  )
  self.maxHeight = maxHeight

  local centerX = self.maxWidth / 2
  local centerY = self.maxHeight / 2

  -- Set the x and y keys of each non-spacer child.
  for _, child in ipairs(children) do
    local width = child:getWidth()
    local height = child:getHeight()

    if align == "center" then
      child.x = centerX - width / 2
      child.y = centerY - height / 2
    elseif align == "north" then
      child.x = centerX - width / 2
      child.y = 0
    elseif align == "south" then
      child.x = centerX - width / 2
      child.y = maxHeight - height
    elseif align == "east" then
      child.x = maxWidth - width
      child.y = centerY - height / 2
    elseif align == "west" then
      child.x = 0
      child.y = centerY - height / 2
    elseif align == "northeast" then
      child.x = maxWidth - width
      child.y = 0
    elseif align == "southeast" then
      child.x = maxWidth - width
      child.y = maxHeight - height
    elseif align == "southwest" then
      child.x = 0
      child.y = maxHeight - height
    else -- assume northwest
      child.x = 0
      child.y = 0
    end
  end

  self.width = maxWidth
  self.height = maxHeight
end

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      parentX = parentX or Glove.margin
      parentY = parentY or Glove.margin
      local x = parentX + self.x
      local y = parentY + self.y
      for _, child in ipairs(self.children) do
        child:draw(x, y)
      end
    end,

    getHeight = function(self)
      return self.maxHeight
    end,

    getWidth = function(self)
      return self.maxWidth
    end
  }
}

--[[
This stacks widgets on top of each other.

To control the position of each widget in the stack,
specify the `align` option with a compass direction or `"center"`.

The parameters are:

- table of options

The supported options are:

- align: "center" or one of the following compass directions:
  "north", "south", "east", "west",
  "northeast", "southeast", "southwest", or "northwest" (default)
--]]
local function ZStack(options, ...)
  local to = type(options)
  assert(to == "table" or to == "nil", "ZStack options must be a table.")

  local instance = options
  instance.kind = "ZStack"
  instance.children = { ... }
  instance.x = 0
  instance.y = 0
  setmetatable(instance, mt)
  layout(instance)
  return instance
end

return ZStack
