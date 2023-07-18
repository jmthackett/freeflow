
local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local InputField = require("InputField")
local inspect = require("inspect")

local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"
local field      = InputField(url)

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
  local byline = doc:css_select('[data-link-name="byline"]')
  local byline = byline:css_select('div')

  -- grab the content
  local content = doc:css_select('div[id~="maincontent"]')
  local content = content:to_xml():gsub("<figure(.-)</figure>","") -- nuke everything inside the figure tag as it is newsletter begging
  local content = xmlua.XML.parse(content)
  local content = content:css_select('p') -- select only p tags
  local content = content:to_xml():gsub("<p(.-)>","\n"):gsub("</p>","\n") -- we're "rendering" with printf, so just replace paragraph tags with newlines

  return headline, standfirst, byline, content
end

local x, y, w, h = love.window.getSafeArea( )

local padding_left = ((w / 100)*10)
local padding_right = w - ((w / 100)*10)

function love.load()
	love.window.setMode(800, 600, {resizable=true, vsync=0, minwidth=400, minheight=300})
end

--local headline = love.graphics.newText(font, headline_h1:content())
--local body = love.graphics.newText(font, standfirst_paragraph:content().."\n\n"..byline_paragraph:content().."\n\n"..processed_content)

local fieldX = 1
local fieldY = 1

headline, standfirst, byline, content = fetch_and_build(field.text)

love.keyboard.setKeyRepeat(true)

function enterkey()
  
end

function love.keypressed(key, scancode, isRepeat)
    if key == "return" then
      headline, standfirst, byline, content = fetch_and_build(field.text)
    else
	  field:keypressed(key, isRepeat)
	end
end

function love.textinput(text)
	field:textinput(text)
end

function love.mousepressed(mx, my, mbutton, pressCount)
	field:mousepressed(mx-fieldX, my-fieldY, mbutton, pressCount)
end
function love.mousemoved(mx, my)
	field:mousemoved(mx-fieldX, my-fieldY)
end
function love.mousereleased(mx, my, mbutton)
	field:mousereleased(mx-fieldX, my-fieldY, mbutton)
end
function love.wheelmoved(dx, dy)
	field:wheelmoved(dx, dy)
end

function love.draw()

  love.graphics.setColor(0, 0, 1)
  for _, x, y, w, h in field:eachSelection() do
	love.graphics.rectangle("fill", fieldX+x, fieldY+y, w, h)
  end

  love.graphics.setColor(1, 1, 1)
  for _, text, x, y in field:eachVisibleLine() do
	love.graphics.print(text, fieldX+x, fieldY+y)
  end

  local x, y, h = field:getCursorLayout()
  love.graphics.rectangle("fill", fieldX+x, fieldY+y, 1, h)

  love.graphics.setBackgroundColor( 0,0,0, 0 )
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(headline:content().."\n\n"..standfirst:content().."\n\n"..byline:content().."\n\n"..content, padding_left, 30, padding_right, "left")
end
