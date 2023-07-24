CREATE TABLE uri (
  id INTEGER PRIMARY KEY,
  name TEXT, 
  protocol TEXT, 
  host TEXT, 
  path TEXT, 
  query TEXT,
  map JSON,
  layout TEXT
);

CREATE INDEX IF NOT EXISTS sites ON uri(host);

INSERT INTO uri(name, protocol, host, path, query, map) 
  VALUES(
  'The Guardian, article content', 
  'https', 
  'www.theguardian.com', 
  '(%d%d%d%d/%a%a%a/%d%d)',
  '//div[@data-gu-name="headline"]//h1 | //div[@data-gu-name="standfirst"]//p | //address[@aria-label="Contributor info"] | //div[@id="maincontent"]/div/p',
  json('{"link": 1, "link_title": 2, "link_text": 3, "authors": 4}'),
  'article_content'
);

INSERT INTO uri(name, protocol, host, path, query, map) 
  VALUES(
  'The Guardian, front page', 
  'https', 
  'www.theguardian.com', 
  '/uk',
  '//div[contains(@id,"container")]//a[@href]/@href | //div[contains(@id,"container")]//a[@aria-label]/@aria-label',
  json('{"link": 1, "link_text": 2, "authors": nil}'),
  'site_index'
);

INSERT INTO uri(name, protocol, host, path, query, map) 
  VALUES(
  'London Review of Books, front page', 
  'https', 
  'www.lrb.co.uk', 
  '',
  '//div[@role="main"]//h2/a[@href]/@href | //div[@role="main"]//h2/a[@href]/text() | //div[@role="main"]//div[@aria-hidden="true"]/p | //div[@role="main"]//h3/a[@href]/text()',
  json('{"link": 1, "link_title": 2, "link_text": 4, "authors": 3}'),
  'site_index'
);

