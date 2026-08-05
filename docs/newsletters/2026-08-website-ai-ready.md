---
subject: Your GrowERP website now talks to the AI assistants too
preheader: Convert your existing site in one run, and it comes out readable for ChatGPT, Claude and Perplexity.
date: 2026-08-05
---

# Your website, now readable by machines as well as people

Two things landed in GrowERP this month, and they belong together.

## Bring your existing website along

You no longer have to rebuild your website to move it into GrowERP. Point the new
website generator at your current site and it reads the pages you have, writes them into
the GrowERP page templates, carries over your logo and images, picks a colour theme from
your branding, and installs the result as a website you own. You find it in the Support
app, under Website generator, and everything it produces stays editable: every page is a
normal content page in the website dialog, so you can rewrite a paragraph, add a page or
change the menu order without touching a template.

Two smaller changes make that safer in daily use. A conversion that fails on one page now
records what went wrong instead of quietly dropping it, and page bodies are stored as
plain HTML, which means what you see in the editor is what gets served.

## Why we then made every page machine readable

More and more people no longer start at a search box. They ask ChatGPT, Claude, Perplexity
or Gemini which supplier to use, and those assistants go and read websites on their behalf.
A modern website is a poor meal for them: thousands of tokens of layout markup wrapped
around a few hundred words of actual information. Some of it gets misread. Some of it
never gets read at all.

So every website GrowERP hosts now publishes a second, clean version of itself:

- **`/llms.txt`** — a short index of the whole site, with a one-line description per page.
- **A markdown twin of every page**, at the same address with `/md/` in front of it. Your
  About page at `/content/about` is also available at `/md/content/about`, as plain text
  with headings, lists and links intact, and a small header giving the title, description,
  the canonical address and the date it last changed.
- **`/sitemap.xml`** and a **`robots.txt`** that names the AI crawlers explicitly and
  welcomes them, instead of the generic rules most sites accidentally ship.
- **Structured data** (schema.org) describing your company, the page and, for shops, the
  products and categories, plus proper page titles, descriptions and share images on every
  page rather than only on a few.

None of this is something you switch on. It is generated from the pages you already have,
per site, on your own domain. If you host a site with us, it is live now: open
`yourdomain.com/llms.txt` and have a look.

## One thing worth doing

Each page in the website dialog has an SEO description field. When it is empty we fall
back to the first sentence of the page, which is usually acceptable and occasionally
clumsy. One sentence per page, written by someone who knows the business, is the single
best improvement you can make to how both search engines and assistants summarise you.

As always, the code is open source, and we would like to hear how it reads for you. Reply
to this mail — it reaches us directly.
