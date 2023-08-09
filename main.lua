local stringx = require("pl.stringx")
local tablex = require("pl.tablex")
local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local InputField = require("InputField")
local inspect = require("inspect")
local math = require("math")
local url_parser = require("net.url")
local sqlite = require("lsqlite3complete")
local omap = require("pl.OrderedMap")
--stringx.import()

-- load love2d window
function love.load()

end

-- misc defaults
local default_url = "freeflow://"
FIELD_PADDING = 5

-- input config
isPressing      = false
pressedWidget   = nil
pressedMouseButton = 0
updateEvent = true

-- freeflow specific widget objects
local urlWidget = InputField(default_url)
local contentWidget = InputField("hello\nworld","multiwrap")

-- widget wrappers
function freeflowUIBar(width, height, objzzz)
  local width = width or 50
  local height = height or 50
  local obj = InputField("hello world!")
  
  --print("pre return" .. inspect(obj) .. "")

  -- this wrapper is only needed for the draw function
  -- in future, maybe iterate over the object's methods
  -- and return them all
  --
  -- or maybe just alter InputField.lua? 
  return {
    draw = function(self, parentX, parentY)
--      print(tablex.keys(obj))
--      print(tablex.values(obj))
--      parentX = parentX or 1
--      parentY = parentY or 1
      obj.x = parentX or obj.x
      obj.y = parentY or obj.y
      
      obj.width = width
      obj.height = height
      obj.alignment = "left"
      obj.font_size = 18
      obj.setEditable = true

      --love.graphics.setScissor( obj.x, obj.y, obj.width, obj.height )
      love.graphics.setBackgroundColor(love.math.colorFromBytes(0, 0, 0))
	  love.graphics.setColor(love.math.colorFromBytes(120, 120, 120))
      love.graphics.rectangle("fill", obj.x, obj.y, obj.width, obj.height)

      local fieldX   = obj.x + FIELD_PADDING
      local fieldY   = obj.y + FIELD_PADDING

	  love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
	  for _, text, x, y in obj:eachVisibleLine() do
	    love.graphics.print(text, fieldX+x, fieldY+y)
	  end

	  local x, y, h = obj:getCursorLayout()
	  love.graphics.rectangle("fill", x+FIELD_PADDING, y+FIELD_PADDING, 1, h)
	  --local windowWidth, windowHeight = love.graphics.getDimensions( )
      --love.graphics.setScissor()
    end,

    setDimensions = function(self, h, w) return obj:setDimensions(h, w) end,
    getX = function(self) return obj.x end,
    getY = function(self) return obj.y end,
    getHeight = function(self) return obj.height end,
    getWidth = function(self) return obj.width end,
    mousePressed = function(self, mx, my, mbutton, pressCount) return obj:mousepressed(mx, my, mbutton, pressCount) end,
    mouseMoved = function(self, mx, my) return obj:mousemoved(mx, my) end,
    mouseReleased = function(self, mx, my, mbutton) return obj:mousereleased(mx, my, mbutton) end,
    wheelMoved = function(self, dx, dy) return obj:wheelmoved(dx, dy) end,
    update = function(self, dt) return obj:update(dt) end,
    resetBlinking = function(self) return obj:resetBlinking() end,
    keyPressed = function(self, key, isRepeat) return obj:keypressed(key, isRepeat) end,
    textInput = function(self, text) return obj:textinput(text) end,
    isBusy = function(self) return obj:isBusy() end,
    hasFocus = function(self) return true end,
    getText = function(self) return obj:getText() end
  }
end

function freeflowContentWidget(width, height, objzzz)
  local width = width or 50
  local height = height or 50
  local obj = InputField("hello\nworld","multiwrap")

  -- this wrapper is only needed for the draw function
  -- in future, maybe iterate over the object's methods
  -- and return them all
  --
  -- or maybe just alter InputField.lua? 
  return {
    draw = function(self, parentX, parentY)
      obj.x = parentX or obj.x
      obj.y = parentY or obj.y

      obj.width = width
      obj.height = height
      obj.alignment = "left"
      obj.font_size = 18
      obj.setEditable = true

      --love.graphics.setScissor( obj.x, obj.y, obj.width, obj.height )
      --love.graphics.setBackgroundColor(love.math.colorFromBytes(120, 120, 200))
	  love.graphics.setColor(love.math.colorFromBytes(220, 220, 220))
      love.graphics.rectangle("fill", obj.x, obj.y, obj.width, obj.height)

      local fieldX   = obj.x + FIELD_PADDING
      local fieldY   = obj.y + FIELD_PADDING

	  love.graphics.setColor(love.math.colorFromBytes(0, 0, 0))
	  for _, text, x, y in obj:eachVisibleLine() do
	    love.graphics.print(text, fieldX+x, fieldY+y)
	  end

	  local x, y, h = obj:getCursorLayout()
	  love.graphics.rectangle("fill", obj.x+FIELD_PADDING, obj.y+FIELD_PADDING, 1, obj.height)
	  local windowWidth, windowHeight = love.graphics.getDimensions( )
      --love.graphics.setScissor( 0, 0, windowWidth, windowHeight )
      --love.graphics.setScissor()
    end,

    setDimensions = function(self, h, w) return obj:setDimensions(h, w) end,    
    getX = function(self) return obj.x end,
    getY = function(self) return obj.y end,
    getHeight = function(self) return obj.height end,
    getWidth = function(self) return obj.width end,
    mousePressed = function(self, mx, my, mbutton, pressCount) return obj:mousepressed(mx, my, mbutton, pressCount) end,
    mouseMoved = function(self, mx, my) return obj:mousemoved(mx, my) end,
    mouseReleased = function(self, mx, my, mbutton) return obj:mousereleased(mx, my, mbutton) end,
    wheelMoved = function(self, dx, dy) return obj:wheelmoved(dx, dy) end,
    update = function(self, dt) return obj:update(dt) end,
    resetBlinking = function(self) return obj:resetBlinking() end,
    keyPressed = function(self, key, isRepeat) return obj:keypressed(key, isRepeat) end,
    textInput = function(self, text) return obj:textinput(text) end,
    isBusy = function(self) return obj:isBusy() end,
    hasFocus = function(self) return true end,
    getText = function(self) return obj:getText() end
  }
end

local width, height = love.graphics.getDimensions( )
print("widget widths:" .. width .. "")
print("widget heights:" .. height .. "")
  
local freeflow = freeflowUIBar(width, 30 , urlWidget)
--print("freeflow object" .. inspect(freeflow) .. "")
local nav = {}
local title = {}
local images = {}
local content = freeflowContentWidget(width, height, contentWidget)
local links = {}

local layout = omap()
layout:set("freeflow",freeflow)
--layout:set("nav",nav)
--layout:set("title",title)
--layout:set("images",images)

layout:set("content",content) -- TODO: check if this is iterable and adjust layout accordingly?
--layout:set("links",links)

-- input helper functions
local function isPointInsideRectangle(pointX,pointY, rectX,rectY, rectW,rectH)
	return pointX >= rectX and pointY >= rectY and pointX < rectX+rectW and pointY < rectY+rectH
end

local function getWidgetAtCoords(x, y)
	for widgetName, widgetWrapper in layout:iter() do
		if isPointInsideRectangle(x, y, widgetWrapper.getX(), widgetWrapper.getY(), widgetWrapper.getWidth(), widgetWrapper.getHeight()) then
			return widgetWrapper, widgetName
		end
	end
	return nil -- No text input at coords.
end

-- initial widget focus
local focusedWidget = nil

-- love2d callbacks

function love.load()
  love.window.setMode(800, 800, {resizable=true, vsync=0, minwidth=400, minheight=300})
  local offsetX = 1
  local offsetY = 1
  for k,v in layout:iter() do
    v:draw(offsetX, offsetY)
    --offsetX = offsetX + v:getWidth()
    offsetY = offsetY + v:getHeight()
  end
end

function love.resize()
    local offsetX = 1
    local offsetY = 1
    for k,v in layout:iter() do
      v:draw(offsetX, offsetY)
      offsetY = offsetY + v:getHeight()
    end
end

function love.draw()
-- TODO: wtf
    local offsetX = 1
    local offsetY = 1
    for k,v in layout:iter() do
      v:draw(offsetX, offsetY)
      offsetY = offsetY + v:getHeight()
    end
end

dtotal = 0
function love.update(dt)
--  if focusedWidget and updateEvent then
--  if updateEvent then
--    dtotal = dtotal + dt
--    print(acc)
--    if (dtotal >= 1) then
--    print("i:" .. i .. "")
--      focusedWidget:draw()
--      local offsetX = 1
--      local offsetY = 1
--      for k,v in layout:iter() do
--        v:draw(offsetX, offsetY)
--        offsetY = offsetY + v:getHeight()
--      end
--      updateEvent = false
--      dtotal = dtotal - 1
--    end
--    i = i + 1
--  end
end

-- handle mouse stuff
function love.mousepressed(mx, my, mbutton, pressCount)
	if not isPressing then
		local hoveredWidget, hoveredWidgetName = getWidgetAtCoords(mx, my)

		if hoveredWidget ~= nil then
            print("Clicked on widget:" .. hoveredWidgetName .. "")
        end
        
		if hoveredWidget then
			focusedWidget = hoveredWidget
			updateEvent = true

			isPressing         = true
			pressedWidget   = focusedWidget
			pressedMouseButton = mbutton

			local fieldX = pressedWidget:getX()
			local fieldY = pressedWidget:getY()
			pressedWidget:mousePressed(mx-fieldX, my-fieldY, mbutton, pressCount)

		else
			focusedWidget = nil
		end
	end
end

function love.mousemoved(mx, my, dx, dy)
	if isPressing then
		local fieldX = pressedWidget:getX() + FIELD_PADDING
		local fieldY = pressedWidget:getY() + FIELD_PADDING
		pressedWidget:mouseMoved(mx-fieldX, my-fieldY)
	end
end

function love.mousereleased(mx, my, mbutton, pressCount)
	if isPressing and mbutton == pressedMouseButton then
		local fieldX = pressedWidget:getX() + FIELD_PADDING
		local fieldY = pressedWidget:getY() + FIELD_PADDING
		pressedWidget:mouseReleased(mx-fieldX, my-fieldY, mbutton)
		isPressing = false
		updateEvent = true
	end
end

function love.wheelmoved(dx, dy)
	-- Scroll field under mouse.
	local hoveredWidget = getWidgetAtCoords(love.mouse.getPosition())

	if hoveredWidget then
		hoveredWidget:wheelMoved(dx, dy)
		updateEvent = true
	end
end

-- handle keyboard stuff
function love.keypressed(key, scancode, isRepeat)
	local fieldIsBusy = (focusedWidget ~= nil and focusedWidget:isBusy())
	updateEvent = true

	-- First handle keys that override InputFields' behavior.
	if key == "tab" and not fieldIsBusy then
		-- Cycle focused input.
		--local i     = indexOf(textInputs, focusedWidget)
		--local shift = love.keyboard.isDown("lshift","rshift")

		--if     not i then  i = 1
		--elseif shift then  i = (i-2) % #textInputs + 1 -- Backwards.
		--else               i =  i    % #textInputs + 1 -- Forwards.
		--end

		--focusedWidget = textInputs[i]
--		focusedWidget:resetBlinking()

	-- Then handle focused InputField (if there is one).
	elseif focusedWidget and focusedWidget:keyPressed(key, isRepeat) then
		-- Event was handled.
	elseif focusedWidget and key == "return" then
        print(focusedWidget:getText())
	-- Lastly handle keys for when no InputField has focus or the key wasn't handled by the library.
	elseif key == "escape" and not fieldIsBusy then
		love.event.quit()
	end
end

function love.textinput(text)
	if focusedWidget then
		focusedWidget:textInput(text)
	end
end

-- modified love.run

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			if love.draw and updateEvent then 
				love.draw()
				updateEvent = false
				love.graphics.present()
			end

			
		end

		if love.timer then love.timer.sleep(0.1) end
	end
end
