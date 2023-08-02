#!/usr/bin/env luajit

local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local inspect = require("inspect")


local protocol = "https://"
local site = {}
local verbose = false
site['name'] = arg[1]

-- fetch specified page
local page, code, headers, status = https.request(protocol .. arg[1])
local err, doc = pcall(function() return xmlua.HTML.parse(page) end)

--if (err ~= false) then
--  print("Unable to parse HTML for " .. arg[1] .. " error:" .. inspect(err))
--end

-- test for RSS
-- TODO: hbrchina.org does this <a href="http://app.hbrchina.org/rss.php" target"_blank">RSS</a> which needs catching if possible
-- TODO: technologyreview.com has a massive horrendous json blob containing this: {"displayIcon":true,"type":"rss","url":"https://www.technologyreview.com/feed/","themeName":"footer","context":"footer"}
local docsearch = doc:search("//link[contains(@type,'application/rss+xml')]")
local err, val = pcall(function() return docsearch[1]:get_attribute("href") end)
if (err ~= false) then
  site['rss'] = val
  if (verbose) then
    print(val)
  end
end

local page, code, headers, status = https.request(protocol .. arg[1] .. "/rss")
if (code == 200) then
  if (verbose) then
    print("RSS found at " .. arg[1] .. "/rss")
  end
  site['rss'] = "" .. arg[1] .. "/rss"
end

-- test for opengraph
local docsearch = doc:search("//meta[contains(@property,'og:')]")
local err, val = pcall(function() return docsearch[1]:get_attribute("property") end)
if (err ~= false) then
  if (verbose) then
    for i,t in ipairs(docsearch) do    
      print("OpenGraph property found - " .. docsearch[i]:get_attribute("property"):gsub("og:","") .. ": " .. docsearch[i]:get_attribute("content"))
    end
  end
  site['opengraph'] = true
end

-- test for html5 article tags
local docsearch = doc:search("//article")
local err, val = pcall(function() return docsearch[1]:name() end)
if (err ~= false) then
  site['html5_article'] = true
  if (verbose) then
    print(val)
  end
end

-- test for html5 subsection
local docsearch = doc:search("//subsection")
local err, val = pcall(function() return docsearch[1]:name() end)
if (err ~= false) then
  site['html5_subsection'] = true
  if (verbose) then
     print(val)
  end
end

-- test for aria tags
-- TODO: map aria annotations to relevant roles
local docsearch = doc:search("//*[@aria-description]")
local err, val = pcall(function() return docsearch[1]:name() end)
if (err ~= false) then
  site['aria_description'] = true
  site['aria'] = true
  if (verbose) then
    print(val)
  end
end

local docsearch = doc:search("//*[@aria-label]")
local err, val = pcall(function() return docsearch[1]:name() end)
if (err ~= false) then
  site['aria_label'] = true
  site['aria'] = true
  if (verbose) then
    print(val)
  end
end

-- test for sitemap.xml
-- TODO: check the url ends in a '/' and add one otherwise
-- TODO: also check the fqdn as a base path in cases where we have a path or a redirect to a path that isn't '/'
local page, code, headers, status = https.request(protocol .. arg[1] .. "/sitemap")
if (code == 200) then
  if (verbose) then
    print("Sitemap found at /sitemap")
  end
  site['sitemap'] = 'sitemap'
end

local page, code, headers, status = https.request(protocol .. arg[1] .. "/sitemap.xml")
if (code == 200) then
  if (verbose) then
    print("Sitemap found at /sitemap.xml")
  end
  site['sitemap'] = 'sitemap.xml'
end

local page, code, headers, status = https.request(protocol .. arg[1] .. "/sitemap_index.xml")
if (code == 200) then
  if (verbose) then
    print("Sitemap found at /sitemap_index.xml")
  end
  site['sitemap'] = 'sitemap_index.xml'
end

print(inspect(site))

return 0
