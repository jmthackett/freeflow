local luacs = require("luacs")
local xmlua = require("xmlua")
local https = require("ssl.https")
local inspect = require("inspect")

local page, code, headers, status = https.request("https://www.lrb.co.uk/feeds/rss")
local doc = xmlua.HTML.parse(page)
local docsearch = doc:search("//item")
print(type(docsearch))

for i, t in ipairs(docsearch) do
  print(i)
  print(inspect(t))
  print(inspect(t:children()))
  for i2, t2 in ipairs(t:children()) do
    print(i2)
    print(t2:name())
    print(t2:content())
  end
  print("\n\n\n")
end
