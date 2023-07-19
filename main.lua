

local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local InputField = require("InputField")
local inspect = require("inspect")

local LG = love.graphics
local LK = love.keyboard

local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"

headline = ""
byline = ""
standfirst = ""
content = "This is the Freeflow home page"

w = 600
h = 600
--text = content

local FIELD_PADDING    = 6
local FONT_LINE_HEIGHT = 1.3
local SCROLLBAR_WIDTH  = 5
local BLINK_INTERVAL   = 0.90

local ENABLE_CJK              = false
local COMPOSITION_BOX_PADDING = 3

local theFont = ENABLE_CJK and LG.newFont("unifont-14.0.02.ttf", 16) or LG.newFont(16)


local textInputs = {
	{
		field     = InputField(url),
		x         = 1,
		y         = 1,
		width     = w,
		height    = 30,
		alignment = "left",
		font_size = 12,
	},
	{
		field = InputField(content,
			"multiwrap"
		),
		x         = 31,
		y         = 31,
		width     = w - 60,
		height    = h - 30,
		alignment = "left",
		setEditable = false,
		font_size = 12,
	},
}

local focusedTextInput = textInputs[1] -- Nil means no focus.

local function indexOf(array, value)
	for i = 1, #array do
		if array[i] == value then  return i  end
	end
	return nil -- Value is not in array.
end

local function isPointInsideRectangle(pointX,pointY, rectX,rectY, rectW,rectH)
	return pointX >= rectX and pointY >= rectY and pointX < rectX+rectW and pointY < rectY+rectH
end

local function getTextInputAtCoords(x, y)
	for textInputNumber, textInput in ipairs(textInputs) do
		if isPointInsideRectangle(x, y, textInput.x, textInput.y, textInput.width, textInput.height) then
			return textInput, textInputNumber
		end
	end
	return nil -- No text input at coords.
end

function fetch_and_build(url) 
  local page, code, headers, status = https.request(url)

  local doc = xmlua.HTML.parse(page)

  -- grab the headline
  local headline = doc:css_select('div [data-gu-name="headline"]')
  local headline = headline:css_select('h1')

  -- grab the standfirst/subheading
  local standfirst = doc:css_select('div [data-gu-name="standfirst"]')
  local standfirst = standfirst:css_select('p')

  -- grab the byline (as in, line denoting who the article is by!)
  local byline = doc:css_select('[rel="author"]')
  local byline = byline:css_select('div')

  -- grab the content
  local content = doc:css_select('div[id~="maincontent"]')
  local content = content:to_xml():gsub("<figure(.-)</figure>","") -- nuke everything inside the figure tag as it is newsletter begging
  local content = xmlua.XML.parse(content)
  local content = content:css_select('p') -- select only p tags
  local content = content:to_xml():gsub("<p(.-)>","\n"):gsub("</p>","\n") -- we're "rendering" with printf, so just replace paragraph tags with newlines

  return headline:content(), standfirst:content(), byline:content(), content
end

local x, y, w, h = love.window.getSafeArea( )

local padding_left = ((w / 100)*10)
local padding_right = w - ((w / 100)*10)

posx = nil
posy = nil

function love.load()
	love.window.setMode(w, x, {resizable=true, vsync=0, minwidth=400, minheight=300})
    posx, posy = love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5
    velx, vely = 30, 30
end

--local headline = love.graphics.newText(font, headline_h1:content())
--local body = love.graphics.newText(font, standfirst_paragraph:content().."\n\n"..byline_paragraph:content().."\n\n"..processed_content)

local fieldX = 1
local fieldY = 1

--headline, standfirst, byline, content = fetch_and_build(field.text)

love.keyboard.setKeyRepeat(true)

local isPressing         = false
local pressedTextInput   = nil
local pressedMouseButton = 0

function love.keypressed(key, scancode, isRepeat)
	local fieldIsBusy = (focusedTextInput ~= nil and focusedTextInput.field:isBusy())

	-- First handle keys that override InputFields' behavior.
	if key == "tab" and not fieldIsBusy then
		-- Cycle focused input.
		local i     = indexOf(textInputs, focusedTextInput)
		local shift = LK.isDown("lshift","rshift")

		if     not i then  i = 1
		elseif shift then  i = (i-2) % #textInputs + 1 -- Backwards.
		else               i =  i    % #textInputs + 1 -- Forwards.
		end

		focusedTextInput = textInputs[i]
		focusedTextInput.field:resetBlinking()
	elseif key == "return" and textInputs[1] then 
	    headline, standfirst, byline, content = fetch_and_build(url)
	    textInputs[2].field.text = ""..headline.."\n\n"..standfirst.."\n\n"..byline.."\n\n"..content..""

    elseif key == "lctrl" and textInputs[2] then
         textInputs[2].font_size = textInputs[2].font_size+2

	-- Then handle focused InputField (if there is one).
	elseif focusedTextInput and focusedTextInput.field:keypressed(key, isRepeat) then
		-- Event was handled.

	-- Lastly handle keys for when no InputField has focus or the key wasn't handled by the library.
	elseif key == "escape" and not fieldIsBusy then
		love.event.quit()
	end
end

function love.textinput(text)
	focusedTextInput.field:textinput(text)
end
function love.mousepressed(mx, my, mbutton, pressCount)
	if not isPressing then
		local hoveredTextInput = getTextInputAtCoords(mx, my)

		if hoveredTextInput then
			focusedTextInput = hoveredTextInput

			isPressing         = true
			pressedTextInput   = focusedTextInput
			pressedMouseButton = mbutton

			local fieldX = pressedTextInput.x + FIELD_PADDING
			local fieldY = pressedTextInput.y + FIELD_PADDING
			pressedTextInput.field:mousepressed(mx-fieldX, my-fieldY, mbutton, pressCount)

		else
			focusedTextInput = nil
		end
	end
end

function love.mousemoved(mx, my, dx, dy)
	if isPressing then
		local fieldX = pressedTextInput.x + FIELD_PADDING
		local fieldY = pressedTextInput.y + FIELD_PADDING
		pressedTextInput.field:mousemoved(mx-fieldX, my-fieldY)
	end
end

function love.mousereleased(mx, my, mbutton, pressCount)
	if isPressing and mbutton == pressedMouseButton then
		local fieldX = pressedTextInput.x + FIELD_PADDING
		local fieldY = pressedTextInput.y + FIELD_PADDING
		pressedTextInput.field:mousereleased(mx-fieldX, my-fieldY, mbutton)
		isPressing = false
	end
end

function love.wheelmoved(dx, dy)
	-- Scroll field under mouse.
	local hoveredTextInput = getTextInputAtCoords(love.mouse.getPosition())

	if hoveredTextInput then
		hoveredTextInput.field:wheelmoved(dx, dy)
	end
end

function love.update(dt)
	if focusedTextInput then
		focusedTextInput.field:update(dt)
	end
end


local extraFont = LG.newFont(12)


function love.draw()
  x, y, w, h = love.window.getSafeArea( )
  textInputs[1].x = 1
  textInputs[1].y = 1
  textInputs[1].width = w
  textInputs[1].height = 30

  textInputs[2].x = 30
  textInputs[2].y = 31
  textInputs[2].width = w - 60
  textInputs[2].height = h - 30
  textInputs[2].field:setEditable(false)
  love.graphics.setBackgroundColor( 0,0,0, 1 )
  love.graphics.setColor(1, 1, 1, 0.5)
  LG = love.graphics
     for i, textInput in ipairs(textInputs) do
		--
		-- Input field.
		--
	    textInput.field:setDimensions(textInput.width-2*FIELD_PADDING, textInput.height-2*FIELD_PADDING)
	    textInput.field:setAlignment(textInput.alignment)
		local field    = textInput.field
		local fieldX   = textInput.x + FIELD_PADDING
		local fieldY   = textInput.y + FIELD_PADDING
		local hasFocus = (textInput == focusedTextInput)

		-- Field info.
		--local text = i .. ", " .. field:getType() .. ", align=" .. field:getAlignment()
        --local text = content
		local y    = textInput.y - 3 - extraFont:getHeight()
		LG.setFont(extraFont)
		LG.setColor(1, 1, 1, .5)
		--LG.print(text, textInput.x, y)

		-- Background.
		LG.setColor(0, 0, 0)
		LG.rectangle("fill", textInput.x, textInput.y, textInput.width, textInput.height)

        --field:setEditable( false )

		-- Contents.
		do
			LG.setScissor(textInput.x, textInput.y, textInput.width, textInput.height)

			-- Selection.
			if hasFocus then
				LG.setColor(.2, .2, 1)
			else
				LG.setColor(1, 1, 1, .3)
			end
			for _, x, y, w, h in field:eachSelection() do
				LG.rectangle("fill", fieldX+x, fieldY+y, w-60, h)
			end

			-- Text.
			LG.setFont(field:getFont())
			LG.setColor(1, 1, 1, (hasFocus and 1 or .8))
			for _, line, x, y in field:eachVisibleLine() do
				LG.print(line, fieldX+x, fieldY+y)
			end

			-- Cursor.
			if hasFocus and (field:getBlinkPhase() / BLINK_INTERVAL) % 1 < .5 then
				local w       = 2
				local x, y, h = field:getCursorLayout()
				LG.setColor(1, 1, 1)
				LG.rectangle("fill", fieldX+x-w/2, fieldY+y, w, h)
			end

			LG.setScissor()
		end

		--
		-- Scrollbars.
		--
		local canScrollH, canScrollV                 = field:canScroll()
		local hOffset, hCoverage, vOffset, vCoverage = field:getScrollHandles()

		local hHandleLength = hCoverage * textInput.width
		local vHandleLength = vCoverage * textInput.height
		local hHandlePos    = hOffset   * textInput.width
		local vHandlePos    = vOffset   * textInput.height

		-- Backgrounds.
		LG.setColor(0, 0, 0, .3)
		if canScrollV then  LG.rectangle("fill", textInput.x+textInput.width, textInput.y,  SCROLLBAR_WIDTH, textInput.height)  end -- Vertical scrollbar.
		if canScrollH then  LG.rectangle("fill", textInput.x, textInput.y+textInput.height, textInput.width, SCROLLBAR_WIDTH )  end -- Horizontal scrollbar.

		-- Handles.
		LG.setColor(.7, .7, .7)
		if canScrollV then  LG.rectangle("fill", textInput.x+textInput.width, textInput.y+vHandlePos,  SCROLLBAR_WIDTH, vHandleLength)  end -- Vertical scrollbar.
		if canScrollH then  LG.rectangle("fill", textInput.x+hHandlePos, textInput.y+textInput.height, hHandleLength, SCROLLBAR_WIDTH)  end -- Horizontal scrollbar.

		--
		-- Focus indication outline.
		--
		if hasFocus then
			local lineWidth = 2

			local x = textInput.x      - lineWidth/2
			local y = textInput.y      - lineWidth/2
			local w = textInput.width  + lineWidth
			local h = textInput.height + lineWidth

			if canScrollV then  w = w + SCROLLBAR_WIDTH  end
			if canScrollH then  h = h + SCROLLBAR_WIDTH  end

			LG.setColor(1, 1, 0, .4)
			LG.setLineWidth(lineWidth)
			LG.rectangle("line", x, y, w, h)
		end
	end

	--love.timer.sleep( 0.5)
	--LG.print(content, 3, LG.getHeight()-3-2*extraFont:getHeight())
--  love.graphics.printf(headline.."\n\n"..standfirst.."\n\n"..byline.."\n\n"..content, padding_left, math.min(vely,30), padding_right, "left")
end
