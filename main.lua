
local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local InputField = require("InputField")
local inspect = require("inspect")
local yui = require("lib.yui")
local T = require("lib.moonspeak")

local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"
local field      = InputField(url)

content = "zzz"

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


--local headline = love.graphics.newText(font, headline_h1:content())
--local body = love.graphics.newText(font, standfirst_paragraph:content().."\n\n"..byline_paragraph:content().."\n\n"..processed_content)

local fieldX = 1
local fieldY = 1

headline, standfirst, byline, content = fetch_and_build(field.text)

function love.load()
	love.window.setMode(800, 600, {resizable=true, vsync=0, minwidth=400, minheight=300})
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local x = math.floor(love.graphics.getWidth())
    local y = math.floor(love.graphics.getHeight())

    ui = yui.Ui:new {
        x = 10, y = 10,

        yui.Rows {
            yui.Label {
                align = "left",
                w = w-20, h = 10,
                text = headline:content()
            },
            yui.Label {
                align = "left",
                w = w-20, h = 40,
                text = standfirst:content()
            },
            yui.Label {
                align = "left",
                w = w-20, h = 90,
                text = byline:content()
            },
            yui.Label {
                align = "left",
                w = w-20, h = 120,
                text = content
            },
        }
    }
end

function love.update(dt)
    ui:update(dt)
end

function love.draw()
    ui:draw()
end
