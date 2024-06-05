#!/usr/bin/env luajit

require("compat53")
local utf8 = require("lua-utf8")
local stringx = require("pl.stringx")
local tablex = require("pl.tablex")
local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local re = require("re")
local inspect = require("inspect")
local math = require("math")
local url_parser = require("net.url")
local sqlite = require("lsqlite3complete")
--

local db = "sites.db" 

function fetch_and_build(url) 
  local result_content = ""
  local result_xml = ""
  local buttons = {}

  -- fetch the page and parse it
--  print("Fetching url:"..url)
  local db = "sites.db" 
  local page, code, headers, status = https.request(url)
  local doc = xmlua.HTML.parse(page)

  -- try common approaches
  
  -- rss: if we find rss, let's assume we're on an index page and skip everything else
  local docsearch = doc:search("//link[contains(@type, 'application/rss+xml')]")
  print(#docsearch)
  local err, val = pcall(function() return docsearch[1]:get_attribute("href") end)
  
  if (#docsearch ~= 0) then
    print("Found RSS!")
    local rss = https.request(val)
    print("Fetched RSS!")
    local rss_doc = xmlua.XML.parse(rss)
    local rss_search = rss_doc:search("//item")
    local rss_content = ""
    
    for i,t in ipairs(rss_search) do
      local err, val = pcall(function() return rss_doc:search("//item/title")[i] end)
--      if (err == false) then
        rss_content = rss_content .. val:content() .. "\n"
--      end
      local err, val = pcall(function() return rss_doc:search("//item/link")[i] end)
--     if (err == false) then
        rss_content = rss_content .. val:content() .. "\n"
--      end
      local err, val = pcall(function() return rss_doc:search("//item/description")[i] end)
--      if (err == false) then
        rss_content = rss_content .. val:content() .. "\n"
--      end
    end

    return rss_content, rss
  end

  -- no joy? let's see if we have a query in the database that tells us how to handle this page
  print("Pre-query (sqlite)")
  local query, _, _ = find_query(url,db)
  if (query == nil and result_content == "") then
    content = "Sorry, we don't know how to display this page yet! Here's what we've got:"
    return result_content, ""
  end
--  print("QUERY:" .. query)
  print("Post-query (sqlite)")
--  print("Pre-query (xmlua)")
  local content = doc:root():search(query)
--  print("Post-query (xmlua)")
  
  local length = 0
  local query_length = 0
  print("pre-split")
  if string.match(query, '|') then
      query_length = stringx.split(query,'|')
      print("post-split")
      for i, t in ipairs(query_length) do -- there must be a better way to get the number of elements in a table, surely?
          length = i
      end
  end
  
  for i, t in ipairs(content) do
    if math.fmod(i,length) == 0 then
    --    result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n-----------\n\n"
    else
    --    result_content = result_content .. content[i]:path() .. "\n\n" .. content[i]:content() .. "\n\n"
    end
    result_content = result_content .. "\n" .. content[i]:content() .. "\n"
  end
  
  for i, t in ipairs(content) do
    if content[i].to_html == nil then
--      print("Skipped converting to html")
    else
      result_xml = result_xml .. content[i]:path() .. "\n\n" .. content[i]:to_html() .. "\n\n"
    end
  end
  if (result_content) then  
    return result_content, result_xml
  end
  -- opengraph
  local docsearch = doc:search("//meta[contains(@property,'og:')]")
  local err, val = pcall(function() return docsearch[1]:get_attribute("property") end)
  if (#docsearch ~= 0) then
  -- we need to parse this
    for i,t in ipairs(docsearch) do 

      print("OG results:")
      print(result_content)

      if (docsearch[i]:get_attribute("property"):gsub("og:","") == "title") then
        result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
      end
      
      if (docsearch[i]:get_attribute("property"):gsub("og:","") == "description") then
        result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
      end
      
      if (docsearch[i]:get_attribute("property"):gsub("og:","") == "image") then
        result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
      end
      
      if (docsearch[i]:get_attribute("property"):gsub("og:","") == "url") then
        result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
      end

      print("---")
    end
  end

  -- test for html5 article tags
  local docsearch = doc:search("//article//p")
  local err, val = pcall(function() return docsearch[1]:name() end)
  if (#docsearch ~=0) then
    for i,t in ipairs(docsearch) do    
      result_content = result_content .. docsearch[i]:content() .. "\n\n"
    end
  end
  
  -- test for html5 subsection
  local docsearch = doc:search("//subsection")
  local err, val = pcall(function() return docsearch[1]:name() end)
  if (err == false) then
    if (verbose) then
       print("subsection:")
       print(val)
    end
  end
  
  -- test for aria tags
  -- TODO: map aria annotations to relevant roles
  local docsearch = doc:search("//*[@aria-description]")
  local err, val = pcall(function() return docsearch[1]:name() end)
  if (err == false) then
    if (verbose) then
--      print("aria-description:")
--      print(val)
    end
  end
  
  local docsearch = doc:search("//*[@aria-label]")
  local err, val = pcall(function() return docsearch[1]:name() end)
  if (err == false) then
    if (verbose) then
--      print("aria-label:")
--      print(val)
    end
  end

  return "", ""
end

function find_query(url, db)
  handle = sqlite3.open(db)
  u = url_parser.parse(url)
  for path,query,map,layout in handle:urows("SELECT path,query,map,layout FROM uri WHERE host='"..u.host.."';") do
--    print(u.path)
    if u.path:match(path) then
--      print("PATH MATCHES")
--      print(path,query,map,layout)
      return query
    end
  end
  -- if we're here, no paths have matched: this needs a sane default
  return nil
end

