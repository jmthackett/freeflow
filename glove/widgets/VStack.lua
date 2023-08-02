local fun = require "glove/fun"

local function layout(self)
  local align = self.align or "start"
  local children = self.children
  local spacerWidth = 0
  local spacing = self.spacing or 0
  local x = self.x or 0
  local y = self.y or 0

  -- Get width of widest child.
  self.maxWidth = fun.max(
    children,
    function(child) return child:getWidth() or 0 end
  )

  -- Count spacers with no size.
  local spacerCount = fun.count(children, isSpacerWithoutSize)

  -- If there are any spacers with no size ...
  if spacerCount > 0 then
    -- Get the total height of the all other children.
    local childrenHeight = fun.sumFn(
      children,
      function(child)
        return isSpacerWithoutSize(child) and 0 or child:getHeight()
      end
    )

    -- Get the number of children that are not spacers
    -- and not preceded by a spacer.
    local gapCount = fun.count(
      children,
      function(child, i)
        if child.kind == "Spacer" then return false end
        local prevChild = children[i - 1]
        return prevChild and prevChild.kind ~= "Spacer"
      end
    )

    -- Account for requested gaps between children.
    childrenHeight = childrenHeight + spacing * gapCount

    local availableHeight = self:getHeight()

    -- Compute the size of each zero width Spacer.
    spacerWidth = (availableHeight - childrenHeight) / spacerCount
  end

  -- Set the x and y keys of each non-spacer child.
  for i, child in ipairs(children) do
    if child.kind == "Spacer" then
      y = y + (child.size or spacerWidth)
    else
      child.y = y

      local prevChild = children[i - 1]
      if prevChild and prevChild.kind ~= "Spacer" then
        child.y = child.y + spacing
      end

      if align == "center" then
        child.x = x + (self.maxWidth - child:getWidth()) / 2
      elseif align == "end" then
        child.x = x + self.maxWidth - child:getWidth()
      else -- assume "start"
        child.x = x
      end

      y = child.y + child:getHeight()
    end
  end
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

      for _, child in ipairs(self.children) do
        if child.drawLater then child:drawLater(x, y) end
      end
    end,

    getHeight = function(self)
      if self.height then return self.height end

      -- If there is a Spacer child then use screen height.
      if self.haveSpacer then return Glove.getAvailableHeight() end

      -- Compute height based on children.
      local children = self.children
      local lastChild = children[#children]
      return lastChild.y + lastChild:getHeight() - self.y
    end,

    getWidth = function(self)
      return self.maxWidth
    end
  }
}

--[[
This arranges widgets vertically.

By default there is no space between the widgets.
To add space, specify the `spacing` option.

To horizontally align the widgets, specify the `align` option
with a value of `"start"` (default), `"center"`, or `"end"`.

The parameters are:

- table of options
- child widgets as individual arguments

The supported options are:

- `align`: "start" (default), "center", or "end"
- `spacing`: positive integer to add space between non-spacer children
--]]
local function VStack(options, ...)
  local to = type(options)
  assert(to == "table" or to == "nil", "VStack options must be a table.")

  local instance = options
  instance.kind = "VStack"
  instance.maxWidth = 0 -- computed in layout method
  local children = { ... }
  instance.children = children
  instance.haveSpacer = fun.some(children, isSpacerWithoutSize)
  instance.x = 0
  instance.y = 0

  setmetatable(instance, mt)
  layout(instance)
  return instance
end

return VStack
