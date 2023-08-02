local stringx = require("pl.stringx")
local url_parser = require("net.url")
local sqlite = require("lsqlite3complete")
local xmlua = require("xmlua")
local https = require("ssl.https")

local url = "https://www.lrb.co.uk/"
local db = "sites.db" 

local PageHandler = {}

PageHandler.new = function()
  local self = {}
  return self
end


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
    end
  end
  -- if we're here, no paths have matched: this needs a sane default
  return nil
end

print(fetch_and_build(url,db))
