function isSpacerWithoutSize(child)
  return child.kind == "Spacer" and not child.size
end

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      -- do nothing
    end,
    getHeight = function(self) return 0 end,
    getWidth = function(self) return 0 end
  }
}

--[[
This widget adds space inside an `HStack` or `VStack`.

Adding a `Spacer` at the end of a table of child widgets
pushes them to the left.

Adding a `Spacer` at the beginning of a table of child widgets
pushes them to the right.

Adding a `Spacer` between widgets in a table of child widgets
pushes the ones preceding it to the left and
pushes the ones following it to the right.

Any number of `Spacer` widgets can be added to a table of widgets.
The amount of space consumed by each is computed by
dividing the unused space by the number of `Spacer` widgets.
--]]
local function Spacer(size)
  local to = type(size)
  assert(to == "number" or to == "nil", "Spacer size must be a number or nil.")

  local instance = { kind = "Spacer", size = size }
  setmetatable(instance, mt)
  return instance
end

return Spacer
