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
local Logging = require("logging.console")
local rex = require("rex_pcre")

local db = "sites.db" 

local logger = Logging.new()
logger:setLevel(logger.INFO)

function check_uri(uri)
  return uri
end

function absolute_uri(fqdn, path)
  return fqdn.."/"..path
end

function is_index(uri)
  return true
end

function fetch_and_build(url) 
  local result_content = ""
  local result_xml = ""
  local buttons = {}

  -- fetch the page and parse it
  logger:info("Fetching url: "..url)
  local db = "sites.db" 
  local page, code, headers, status = https.request(url)
  local doc = xmlua.HTML.parse(page)

  logger:info("Checking for a site specific query")
  local status, type = pcall(function()
      return find_page_type(url, db)
  end)

  print(type)

  -- try common approaches
  -- sitemap.xml: 
  if (type == "site_index") then
    logger:info("Searching for sitemap")
  --  sitemap / rss / opengraph
    local u = url_parser.parse(url)
    logger:info("Searching for sitemap.xml for "..u.host)
    local robots = https.request("https://"..u.host.."/robots.txt")

    local match = lpeg.match
    local sitemap_uri = rex.match(robots,'Sitemap: (.*)')
    local sitemap = https.request(sitemap_uri)
    local doc = xmlua.XML.parse(sitemap)
    -- steps here:
    -- is the sitemap a list of urls (articles) or a list of sitemaps? 
    -- https://www.ft.com/sitemaps/index.xml has the latter: sort by date and take latest
  end

  -- rss: if we find rss, let's assume we're on an index page and skip everything else
  logger:info("Searching for RSS")
  local docsearch = doc:search("//link[contains(@type, 'application/rss+xml')]")
  local err, val = pcall(function() return docsearch[1]:get_attribute("href") end)
  
  if (#docsearch ~= 0) then
    logger:info("Found RSS: "..val)
    -- TODO: use check_uri to see if this is an absolute path and absolute_uri to fix it if not
    local rss = https.request(val)
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
    logger:info("Returning parsed RSS")
    return rss_content, rss
  end

  logger:info("Checking for a site specific query")
  local status, query = pcall(function()
      return find_query(url, db)
  end)

  if (query == nil) then
    logger:info("No query found, attempting guesswork")

  -- test for html5 article tags
    logger:info("Testing for HTML5 article tags")
    local docsearch = doc:search("//article//p")
    local err, val = pcall(function() return docsearch[1]:name() end)
    if (#docsearch ~= 0) then
      logger:info("Found HTML5 article tags")
      for i,t in ipairs(docsearch) do
        result_content = result_content .. docsearch[i]:content() .. "\n\n"
      end
      return result_content, ""
    end
  
  -- test for html5 subsection
    local docsearch = doc:search("//subsection")
    local err, val = pcall(function() return docsearch[1]:name() end)
    if (#docsearch ~= 0) then
      logger:info("Found HTML5 article tags")
      for i,t in ipairs(docsearch) do
        result_content = result_content .. docsearch[i]:content() .. "\n\n"
      end
      return result_content, ""
    end
  
  -- test for aria tags
  -- TODO: map aria annotations to relevant roles
    local docsearch = doc:search("//*[@aria-description]")
    local err, val = pcall(function() return docsearch[1]:name() end)
    if (#docsearch ~= 0) then
      logger:info("Found HTML5 article tags")
      for i,t in ipairs(docsearch) do
        result_content = result_content .. docsearch[i]:content() .. "\n\n"
      end
      return result_content, ""
    end
  
    local docsearch = doc:search("//*[@aria-label]")
    local err, val = pcall(function() return docsearch[1]:name() end)
    if (#docsearch ~= 0) then
      logger:info("Found HTML5 article tags")
      for i,t in ipairs(docsearch) do
        result_content = result_content .. docsearch[i]:content() .. "\n\n"
      end
      return result_content, ""
    end

    -- opengraph
    logger:info("Checking for OpenGraph properties")
    local docsearch = doc:search("//meta[contains(@property,'og:')]")
    local err, val = pcall(function() return docsearch[1]:get_attribute("property") end)
    if (#docsearch ~= 0) then
    -- we need to parse this
      for i,t in ipairs(docsearch) do

        if (docsearch[i]:get_attribute("property"):gsub("og:","") == "title") then
          logger:info("OpenGraph results[title]: "..result_content)
          result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
        end
      
        if (docsearch[i]:get_attribute("property"):gsub("og:","") == "description") then
          logger:info("OpenGraph results[description]: "..result_content)
          result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
        end
      
        if (docsearch[i]:get_attribute("property"):gsub("og:","") == "image") then
          logger:info("OpenGraph results[image]: "..result_content)
          result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
        end
      
        if (docsearch[i]:get_attribute("property"):gsub("og:","") == "url") then
          logger:info("OpenGraph results[url]: "..result_content)
          result_content = result_content .. docsearch[i]:get_attribute("content") .. "\n\n"
        end
      end
      return result_content, ""
    end

    return result_content, result_xml
  end

  logger:info("Attempting query")

  local content = doc:root():search(query)
  local length = 0
  local query_length = 0
  if string.match(query, '|') then
    query_length = stringx.split(query,'|')
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

  return result_content, result_xml
end

function find_page_type(url, db)
  handle = sqlite3.open(db)
  u = url_parser.parse(url)
  for path,query,map,layout in handle:urows("SELECT path,query,map,layout FROM uri WHERE host='"..u.host.."' AND path = '"..u.path.."';") do
    logger:info("Page layout type: "..layout.." for "..u.path.."")
    if (layout) then
      return layout
    end
  end

  for path,query,map,layout in handle:urows("SELECT path,query,map,layout FROM uri WHERE host='"..u.host.."';") do
    logger:info("Page layout type: "..layout)
    if (layout) then
      return layout
    end
  end
  return nil
end

function find_query(url, db)
  local logger = Logging.new()
  handle = sqlite3.open(db)
  u = url_parser.parse(url)
  for path,query,map,layout in handle:urows("SELECT path,query,map,layout FROM uri WHERE host='"..u.host.."';") do
    if u.path:match(path) then
--      logger:info("PATH MATCHES")
--      logger:info(path,query,map,layout)
      return query
    end
  end
  -- if we're here, no paths have matched: this needs a sane default
  return nil
end

