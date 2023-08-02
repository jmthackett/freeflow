local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local lpeg = require("lpeg")
local re = require("re")
local inspect = require("inspect")

local url = "https://www.theguardian.com/education/2023/jul/14/rishi-sunak-force-english-universities-cap-low-value-degrees"
local page, code, headers, status = https.request(url)

local doc = xmlua.HTML.parse(page)
local content = doc:root():search([[
  //div[@data-gu-name='headline']//h1 
  | //div[@data-gu-name='standfirst']//p
  | //address[@aria-label='Contributor info']
  | //div[@id='maincontent']/div/p
]])

for i, t in ipairs(content) do
  print(content[i]:content().."\n")
end
