
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
local glove = require("glove")
local url_parser = require("net.url")
local sqlite = require("lsqlite3complete")
local colors = require "glove/colors"
local fonts = Glove.fonts
local pprint = require "glove/pprint"

local fieldX = 80
local fieldY = 50

stringx.import()

local db = "sites.db" 

-- freeflow functions
function fetch_and_build(url,db) 
  print("Fetching url:"..url)
  local page, code, headers, status = https.request(url)
  local doc = xmlua.HTML.parse(page)
  local query, _, _ = find_query(url,db)
  local content = doc:root():search(query)
  local result_content = ""
  local result_xml = ""
  local buttons = {}
  
  local length = 0
  local qlength = stringx.split(query,'|')
  for i, t in ipairs(qlength) do -- there must be a better way to get the number of elements in a table, surely?
    length = i
  end
  
  for i, t in ipairs(content) do
    if math.fmod(i,length) == 0 then
      result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n-----------\n\n"
    else
      result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n"
    end
  end
  
  for i, t in ipairs(content) do
    if content[i].to_html == nil then
      -- print("Skipped converting to html due to error")
    else
      result_xml = result_xml .. content[i]:path() .. "\n\n" .. content[i]:to_html() .. "\n\n"
    end
  end
  
  return result_content, result_xml
end

function find_query(url, db)
  handle = sqlite3.open(db)
  u = url_parser.parse(url)
  for path,query,map,layout in handle:urows("SELECT path,query,map,layout FROM uri WHERE host='"..u.host.."';") do
    print(u.path)
    if u.path:match(path) then
      print("PATH MATCHES")
      print(path,query,map,layout)
      return query
    else
--      print("PATH DOES NOT MATCH")
--      print(path,query,map,layout) 
    end
  end
  return nil
end
--end freeflow functions

local LG = love.graphics
local LK = love.keyboard

local windowWidth, windowHeight = love.graphics.getDimensions()

local page_xml = "<example>This is the XML pane</example>"
local query = "//div[@role='main']//h2/a[@href]/@href | //div[@role='main']//h2/a[@href]/text() | //div[@role='main']//div[@aria-hidden='true']/p | //div[@role='main']//h3/a[@href]/text()"
local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"
local url = "https://www.theguardian.com/politics/2023/jul/19/sunak-braverman-and-city-regulator-wade-into-farage-banking-row"
local url = "https://www.lrb.co.uk/"
local content = "This is the Freeflow home page"

local container

local function InputFieldWrapperWidget(width, height, obj)
  color = color or colors.white
  width = width or 50
  height = height or 50

  return {
    draw = function(self, parentX, parentY)
      obj = obj
      obj.x = parentX + self.x
      obj.y = parentY + self.y
      obj.width = width
      obj.height = height


	  love.graphics.setColor(0, 0, 1)      
	  for _, x, y, w, h in field:eachSelection() do
		love.graphics.rectangle("fill", parentX+x, parentY+y, w, h)
	  end

	  love.graphics.setColor(1, 1, 1)
	  for _, text, x, y in field:eachVisibleLine() do
	    love.graphics.print(text, parentX+x, parentY+y)
	  end

	  local x, y, h = field:getCursorLayout()
	  love.graphics.rectangle("fill", parentX+x, parentY+y, 1, h)
	  
      parentX = parentX + self.x
      parentY = parentY + self.y
    end,

    getHeight = function(self) return obj.height end,
    getWidth = function(self) return obj.width end,
    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        Glove.setFocus(self)
        
	    obj:mousepressed(clickX, clickY)
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
end

field = InputField("hello world") 

local function createUI()
  local button = Glove.Button("Hello world", {
    buttonColor = Glove.colors.white,
    font = fonts.default12,
    labelColor = Glove.colors.black,
    onClick = function()
      print("got click")
    end
  })

  container = Glove.VStack(
      { width = Glove.getAvailableWidth() },
      InputFieldWrapperWidget(Glove.getAvailableWidth()-10, 20, field),
      button
    )
end

function love.load()
  createUI()
end
zzz = 0

function love.update(dt)
  createUI()
--  zzz = zzz+1
  
--  if zzz > 100 then

--    local button = Glove.Button("zzz", {
--      buttonColor = Glove.colors.white,
--      font = fonts.default12,
--      labelColor = Glove.colors.black,
--      onClick = function()
--        print("got click")
--      end
--    })
  
--    container = Glove.VStack(
--      { width = Glove.getAvailableWidth() },
--      MultiLineInputFieldWrapperWidget(Glove.getAvailableWidth()-10, 20, field),
--      button,
--      Glove.Text("NICKI MINAJ")
--    )
--  end
end

function love.draw()
  container:draw()
end

function love.resize()
  createUI()
end

love.keyboard.setKeyRepeat(true)

function love.keypressed(key, scancode, isRepeat)
	field:keypressed(key, isRepeat)
end

function love.textinput(text)
	field:textinput(text)
end

function love.mousepressed(mx, my, mbutton, pressCount)
    Glove.mousePressed(mx, my, mbutton, pressCount)
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
