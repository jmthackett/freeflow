local love = require "love"
local g = love.graphics

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      if self.x and self.y then
        local rotation = 0
        g.draw(
          self.image,
          parentX + self.x,
          parentY + self.y,
          rotation,
          self.scale,
          self.scale
        )
      end
    end,

    getHeight = function(self)
      return self.image:getHeight() * self.scale
    end,

    getWidth = function(self)
      return self.image:getWidth() * self.scale
    end
  }
}

--[[
This widget displays an image.

The parameters are:

- filePath: path to the image file
- table of options

The supported options are:

- `height`: of the image (aspect ratio is preserved)
--]]
local function Image(filePath, options)
  local to = type(options)
  assert(to == "table" or to == "nil", "Image options must be a table.")

  local image = g.newImage(filePath)

  local instance = options or {}
  instance.kind = "Image"
  instance.filePath = filePath
  instance.image = image

  local width, height = image:getDimensions()
  local scale = 1
  if options.height then
    scale = options.height / height
  end

  instance.scale = scale

  setmetatable(instance, mt)
  return instance
end

return Image
