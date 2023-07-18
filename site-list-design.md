# Design ideas

There are a few different ways for us to describe pages we'll want to grab content from. 

## Principles

* Be as easy to do for any vaguely technical person as is humanly possible. No code is preferred, if possible, otherwise it should be code that will happily execute in a sandbox.
* Invert the selection criteria that adblockers use: we want to be a content grabber, which implicitly means blocking ads, dark patterns, and all the rest
* Rely on premade site layouts: most sites are pretty generic - lists of content, content, forms (contact, comment, forums, etc), baskets and checkout, etc. Later there might be room for site-specific UIs if there's demand, but I'd like to see how far this can go without them.
* All styling to be done locally
* No javasript, ever

# Layouts

I'm imagining a few basic layouts to start with:

* News/blog oriented front pages
* News/blog oriented content pages

As a bonus (and not described below) query options so that paywall unblocking can be baked in by default. 

# Designing content grabbing

There are a few options for this so I've laid them out in pseudo-config below. Essentially we need a non-programmatic way to return strings for each return value we want, nicely formatted and html free.

## Yaml document, defining 

```
---
- name: theguardian.com
  alias: ["www.theguardian.com"]
  paths: 
    - layout: content 
      uri_selectors: 
        - "(%d%d%d%d/%a%a%a/%d%d)"
      page_parts:
        nav:
          - 'some selector to grab <a> tags from the nav'
        headline:
          - 'div [data-gu-name="headline"]'
          - 'h1'
        standfirst: 
          - 'div [data-gu-name="standfirst"]'
          - 'p'
        byline:
          - '[data-link-name="byline"]'
          - 'div'
        content:
          - 'div[id~="maincontent"]' 
          - '<figure(.-)</figure>' # this is a gsub
          - 'p'
          - '<p(.-)>:\n' # another gsub
          - '</p>:\n' # another gsub
    - layout: front
      uri_selectors:
        - "/uk" 
        - "/world"
      page_parts:
        nav:
          - 'some selector to grab <a> tags from the nav' 
        links:
          - 'some selector to grab images if they exist'
          - 'some selector to grab <a> tags from the'
        search: 
          - 'some selector so we can grab the content of the form action if there's a search bar'
```

This might be nice, but yaml parsing could be slow, especially if the file is big.

## Plaintext

This is inspired by the format used in ublock origin's filtering: https://github.com/uBlockOrigin/uAssets/blob/master/filters/filters-2023.txt

It is limited but can be parsed by splitting but is likely to be a pain to extend.

```
theguardian.com:'(%d%d%d%d/%a%a%a/%d%d)':ARTICLE_CONTENT:headline:'div [data-gu-name="standfirst"]':standfirst:'div [data-gu-name="standfirst"]':byline:'div [data-link-name="byline"]':content:'div[id~="maincontent"]':
```

Suffers from the same probable inability to index.

## SQLite

Probably the most robust approach but also complicated, I'm thinking something like what is implied by this pseudocode:


```
> SELECT id, uri_path FROM urls WHERE uri='theguardian.com'; 
| 1 | (%d%d%d%d/%a%a%a/%d%d) |
| 2 | "/" |

> SELECT section, selector, type FROM selectors WHERE urls_id = '1' ORDER_BY section ASC, order ; # grab everything that references 

| "nav" | 'some selector to grab <a> tags from the nav' | "css" |
| "headline | 'div [data-gu-name="headline"]' | "css" |
| "headline | 'h1' | "css" |
| "standfirst" | 'div [data-gu-name="standfirst"]' | "css" |
| "standfirst" | 'p' | "css" |
| "byline" | '[data-link-name="byline"]' | "css" |
| "byline" | 'div' | "css" |
| "content" | 'div[id~="maincontent"]' | "css" |
| "content" | '<figure(.-)</figure>' | "gsub" |
| "content" | 'p' | "css" |
| "content" | '<p(.-)>:\n' | "gsub" |
| "content" | '</p>:\n' | "gsub" |
```

This approach feels most promising, although slightly annoying for people trying to contribute. It could be that an sqlite database is distributed to end users but built from one of the two above formats. 
