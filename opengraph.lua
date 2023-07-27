local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local inspect = require("inspect")

local page, code, headers, status = https.request("https://www.lrb.co.uk/feeds/rss")
local doc = xmlua.HTML.parse(page)
local docsearch = doc:search("//item")
print(type(docsearch))

--[[
//meta[@property='og:title']/@content
//meta[@property='og:type']/@content
//meta[@property='og:image']/@content
//meta[@property='og:url']/@content
//meta[@property='og:description']/@content
//meta[@property='og:site_name']/@content
//meta[@property='og:locale']/@content
//meta[@property='og:article:published_time']/@content
//meta[@property='og:article:modified_time']/@content
]]
