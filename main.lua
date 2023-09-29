#!/usr/bin/env luajit

require("compat53")
local utf8 = require("lua-utf8")
local stringx = require("pl.stringx")
local tablex = require("pl.tablex")
local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local inspect = require("inspect")
local math = require("math")
local url_parser = require("net.url")
local sqlite = require("lsqlite3complete")

fl = require("moonfltk")
fl.scheme("gtk+")
--

win = fl.window(400, 800, arg[0])

local db = "sites.db" 

function fetch_and_build(url) 
  print("Fetching url:"..url)
  local db = "sites.db" 
  local page, code, headers, status = https.request(url)
  local doc = xmlua.HTML.parse(page)
  print("Pre-query (sqlite)")
  local query, _, _ = find_query(url,db)
  if query == nil then
    content = "Sorry, we don't know how to display this page yet!"
    return content, ""
  end
  print("QUERY:" .. query)
  print("Post-query (sqlite)")
  print("Pre-query (xmlua)")
  local content = doc:root():search(query)
  print("Post-query (xmlua)")
  local result_content = ""
  local result_xml = ""
  local buttons = {}
  
  local length = 0
  print("pre-split")
  local qlength = stringx.split(query,'|')
  print("post-split")
  for i, t in ipairs(qlength) do -- there must be a better way to get the number of elements in a table, surely?
    length = i
  end
  
  for i, t in ipairs(content) do
    --if math.fmod(i,length) == 0 then
    --  result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n-----------\n\n"
    --else
    --  result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n"
    --end
    result_content = result_content .. "\n" .. content[i]:content() .. "\n"
  end
  
  for i, t in ipairs(content) do
    if content[i].to_html == nil then
      print("Skipped converting to html due to error")
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
    end
  end
  -- if we're here, no paths have matched: this needs a sane default
  return nil
end



--
function urlbar_callback(val, buf)
  print("pre-fetch")
  print(val:value())
  print("checking url parses")
  u, err = url_parser.parse(val:value())
  print(u.scheme)
  print(err)
  print("parsed url")
  if u.scheme ~= nil then
    content, xml = fetch_and_build(val:value())
  else
    content = "Sorry, we don't know how to display this page yet"
  end
  print("post-fetch")
  print(content)
  buf:text(content)
end
--

textbuf = fl.text_buffer()

input = fl.input(1, 1, 400, 20, "address bar")
input:callback(urlbar_callback, textbuf)

text = fl.text_display(1, 20, 400, 800)
text:wrap_mode('at bounds', 0)
textbuf:text("Welcome to freeflow - this is a web browser which tries to tame the web by only displaying content.")
text:buffer(textbuf)

win:done() -- 'end' is a keyword in Lua
win:show(arg[0], arg)

return fl.run()
