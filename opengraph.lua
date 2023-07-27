local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local inspect = require("inspect")

opengraph = [[
//meta[contains(@property,"og:")]
]]

local page, code, headers, status = https.request("https://www.theguardian.com/books/2023/jul/27/big-birmingham-bookshop-crawl-booksellers-thriving")
local doc = xmlua.HTML.parse(page)
local docsearch = doc:search(opengraph)
print(type(docsearch))
print(inspect(docsearch))

for i,t in ipairs(docsearch) do
  print(docsearch[i]:get_attribute("property"):gsub("og:","") .. ": " .. docsearch[i]:get_attribute("content"))
end
