
local sqlite3 = require("sqlite3")
local url_parser = require("net.url")
local inspect = require("inspect")
local https = require("ssl.https")
local db = sqlite3.open("sites.db")
local luacs = require("luacs")
local xmlua = require("xmlua")
local lpeg = require("lpeg")
local re = require("re")

local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"

function get_site_handlers(url,db)
  local u = url_parser.parse(url)
  local paths = db:rows("SELECT path, section, sequence, type, selector FROM uri WHERE host ='"..u.host.."' ORDER BY section, sequence;")
  local layout = {}
  for row in paths do
    if u.path:match(row['path']) then
      local section = row['section']
      local sequence = tonumber(row['sequence'])
      if type(layout[section]) == "table" then
        layout[section][sequence] = { type = row['type'], selector = row['selector'] }
      else
        layout[section] = {}
        layout[section][sequence] = { type = row['type'], selector = row['selector'] }
      end
    end
  end

  return layout
end

local handler = get_site_handlers(url,db)

local page, code, headers, status = https.request(url)
--local doc = xmlua.HTML.parse(page)

local content = {}

for k,v in pairs(handler) do
  content[k] = xmlua.HTML.parse(page)
end

for k,v in ipairs(handler) do
  for sectionk, sectionv in ipairs(v) do
    if sectionv.type == "css" then
      content[k] = content[k]:css_select(sectionv.selector)
    elseif sectionv.type == "xpath" then
      print("No examples of this, skipping")
      --content[k] = content[k]:css_select(sectionv.selector)
    elseif sectionv.type == "gsub" then
      regex, sub = sectionv.selector:match("(.-)::(.-)")
      content[k] = content[k]:to_html():gsub(regex,sub)
      content[k] = xmlua.HTML.parse(content[k])
      content[k] = content[k]
    else
      print("SECTION TYPE UNRECOGNISED, IGNORING")
    end
  end
end

print(inspect(content))

print(inspect(content.content)

--return layout, content

  -- grab the headline
--  local headline = doc:css_select('div [data-gu-name="headline"]')
--  local headline = headline:css_select('h1')

  -- grab the standfirst/subheading
--  local standfirst = doc:css_select('div [data-gu-name="standfirst"]')
--  local standfirst = standfirst:css_select('p')

  -- grab the byline (as in, line denoting who the article is by!)
--  local byline = doc:css_select('[rel="author"]')
--  local byline = byline:css_select('div')

  -- grab the content
--  local content = doc:css_select('div[id~="maincontent"]')
--  local content = content:to_xml():gsub("<figure(.-)</figure>","") -- nuke everything inside the figure tag as it is newsletter begging
--  local content = xmlua.XML.parse(content)
--  local content = content:css_select('p') -- select only p tags
--  local content = content:to_xml():gsub("<p(.-)>","\n"):gsub("</p>","\n") -- we're "rendering" with printf, so just replace paragraph tags with newlines

--  return headline:content(), standfirst:content(), byline:content(), content
