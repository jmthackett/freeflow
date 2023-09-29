# Freeflow

Freeflow is like reader mode, but for the entire web. Its aim is to present all content on the internet using desktop widgets, with standardised layouts and interactivity.

# Approach

Most sites are well structured enough to lend themselves to parsing. We do things like:

* Grab the OpenGraph properties of pages that have them
* Grab all paragraphs nested within an <article> tag
* Fall back to site-specific xpath queries if there's nothing else

# Why?

The internet sucks. There, I said it.

The modern internet is a hellscape of modals, advertising, subtle tracking tricks, and it is largely the fault of modern web standards. Users don't drive standards creation, gigantic companies do - usually gigantic companies with an interest in advertising and profiling users.

Solving this can't be done by playing the same game as those companies. Users can't coordinate well enough or invest deeply enough to produce a truly user friendly browser. So instead, Freeflow sets out to dispense with everything the user isn't looking for. 

Some of the techniques Freeflow uses piggyback on technology the ad companies demand. In particular, sitemaps and opengraph. These give us very easy to parse metadata that allows us to move from reader mode only on pages which present a single article, to displaying the entirety of the sitemap (or RSS feed) as the site's index. In this way, we can standardise navigation and discovery as well as content display.

# Status

This is a hobby project. Sorry.

My plan is as follows, with no ETA:

* 1.0 - a portable executable that will display most content on the internet, including front pages of news sites and results from search engines.
* 2.0 - support for images, video, and audio.
* 3.0 - support for interactivity via userscripts.

I'm intending on using small, portable libraries that can be vended wherever possible: LuaJIT is small, as is FLTK. I'm hoping to vendor cURL and libxml2 and potentially contribute a rockspec for static compilation for each, as is the case with lua's sqlite3-complete package.

# Copyright

GPLv3 unless otherwise noted, copyright John Hackett 2023.
