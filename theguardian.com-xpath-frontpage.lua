local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local inspect = require("inspect")

local url = "https://www.theguardian.com/uk"
local page, code, headers, status = https.request(url)

local doc = xmlua.HTML.parse(page)
local content = doc:root():search([[
  //section//a/@href || //section//a/@data-link-name
]])


for i, t in ipairs(content) do
  print(content[i]:content().."\n")
end
