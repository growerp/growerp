# GrowERP User Manual — Website Generator

This manual explains how to turn an existing company website into a GrowERP-hosted
website with its own owner (tenant), using the **website generator**: the
`/convert-website` skill plus the `import#WebsiteOwner` backend service.

The result is a live website served by GrowERP on the company's own domain names, with
the company's logo and photos, that the company can afterwards edit itself in the admin
app — no files, no redeploy.

> **Audience:** whoever performs the conversion (a GrowERP consultant or support user).
> You need a running GrowERP backend and Claude Code in the `growerp` repository.
> The company itself needs nothing beyond a browser and their admin login.

---

## 1. What you get

```
  existing website                  one data file                    live in GrowERP
  ────────────────                  ─────────────                    ───────────────
  www.example.com  ──scrape──→  ExampleOwnerImportData.xml  ──import──→  owner (tenant)
    pages                          wiki space + pages                    admin user
    colours                        websiteColor.json                     company + store
    logo, photos                   images as base64                      website on the
    address, phone                 ownerSpec.json                        real hostnames
```

Two steps, two tools:

| Step | Tool | Produces |
|---|---|---|
| Convert | `/convert-website` skill (Claude Code) | `backend/data/<Name>OwnerImportData.xml` |
| Install | `import#WebsiteOwner` service (backend) | owner, admin login, company, store, live site |

The data file is self-contained and repeatable: keep it in the repository and you can
install the same website on any GrowERP backend.

Worked examples are shipped in the repository:
`backend/data/AccuGeoOwnerImportData.xml` (light theme, navbar dropdowns, hidden page)
and `backend/data/AntWebsysOwnerImportData.xml` (dark theme, single-page-app source).

---

## 2. Before you start

**1. A running backend.** `java -jar moqui.war no-run-es` in `moqui/`, reachable on
`http://localhost:8080`.

**2. An admin e-mail address you control.** This becomes the login of the new owner and
receives the welcome mail and any password reset. Do **not** use an address scraped from
the website — use the customer's real address, or your own if you are preparing a demo.
The address found on the website is stored separately as the *company* e-mail and shown
in the site footer.

**3. The domain names the site should answer on.** Usually `example.com`,
`www.example.com`. A test name `<company>.localhost:8080` is added automatically so you
can view the result before touching DNS.

**4. Decide the currency** (`USD`, `EUR`, `THB`, …) — it becomes the company's base
currency and cannot be changed casually afterwards.

---

## 3. Step 1 — convert the website

In Claude Code, in the `growerp` repository:

```
/convert-website https://www.example.com \
    --admin-email admin@example.com \
    --admin-first Jane --admin-last Doe \
    --company-name "Example Liners, Inc." \
    --currency USD
```

Anything you leave out is asked for. Optional:
`--hostnames example.com,www.example.com` and `--app AppAdmin` (the GrowERP application
the owner is registered for).

What happens, and where you can steer it:

1. **Inventory** — every page of the source site is listed and mapped to a GrowERP page
   type. Pages that GrowERP already provides (product lists, search, cart) are dropped.
2. **Structure** — many pages are grouped two levels deep (`products/pvc`,
   `applications/canals`), which produces one navbar dropdown per group. Rarely-visited
   detail pages get a `_` in front of the name: still reachable by link, hidden from the
   menus.
3. **Theme** — the brand colours are read from the source site and turned into the 16
   GrowERP theme values, light or dark.
4. **Assets** — the logo and the meaningful photos are downloaded and embedded in the
   data file. Sprites, icons and tracking pixels are skipped.
5. **Pages** — each page is rewritten in the GrowERP template style, so it inherits the
   navbar, footer, dark/light mode, mobile menu and cookie handling.

The result is written to `backend/data/<Name>OwnerImportData.xml`. Read it if you like —
the page texts are plain HTML inside the file — but you do not have to edit it by hand:
everything can be changed later in the admin app.

> **Not converted:** dated blog or news post lists. GrowERP has no post-list page type
> yet. Individual posts can be converted as hidden pages with a hand-made index page;
> the skill will tell you when it finds a blog.

---

## 4. Step 2 — install the website

This creates the owner and everything under it.

Preferred, from Claude Code:

```
import#WebsiteOwner
    location: component://growerp/data/ExampleOwnerImportData.xml
    siteId:   EXAMPLE
    password: <optional; a random one is generated if omitted>
```

If the assistant answers *"Unknown service name"*, its service list dates from before the
backend started. Use the equivalent call directly — same result, no restart needed:

```bash
curl -s -u SystemSupport:moqui -X POST \
  'http://localhost:8080/apps/tools/Service/ServiceRun/runJson' \
  --data-urlencode 'serviceName=growerp.100.ImportExportServices100.import#WebsiteOwner' \
  --data-urlencode 'location=component://growerp/data/ExampleOwnerImportData.xml' \
  --data-urlencode 'siteId=EXAMPLE'
```

You get back:

```json
{
  "ownerPartyId"   : "100048",
  "companyPartyId" : "100050",
  "adminPartyId"   : "100049",
  "productStoreId" : "100003",
  "password"       : "qqqqqq9!",
  "messages"       : "Account created with username admin@example.com\n"
}
```

**Write the password down.** It is shown once and cannot be read back; after that the
only way in is the password-reset mail.

The import is one transaction: if anything fails, nothing is created and you can simply
fix and retry. It also refuses to run twice — see §8.

---

## 5. Step 3 — check the result

The site is immediately live on its test hostname. Replace the host with any of the
hostnames from the file:

```bash
H='Host: example.localhost:8080'
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/content/about
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/getLogo
```

Or open a browser at `http://example.localhost:8080/` (most systems resolve any
`*.localhost` name automatically).

Walk through this short list:

| Check | Expected |
|---|---|
| Home page and every menu item | opens, no error page |
| Logo top left and in the footer | the company's own logo, not the GrowERP one |
| Photos on the pages | visible, not broken images |
| Footer address, phone, e-mail | the details from the original site |
| Navbar dropdowns | one per page group |
| Phone-width window | hamburger menu opens and lists all pages |
| Dark/light | text stays readable on every background |

---

## 6. Step 4 — hand it over to the customer

Log in to the **admin app** with the admin e-mail and the password from §4, then open
**Website** in the menu. Everything the generator produced is editable there:

- **Website Info** — site title, website URL, Google measurement id, Stripe key, and
  the **Website Template** (leave on *Modern Tailwind*; *Legacy* is the old template).
  Also the Twitter/X, Facebook, Instagram, YouTube, LinkedIn and Substack URLs that
  appear in the footer.
- **Website Colours** — the theme. Switch **Light/Dark**, adjust individual colours, or
  **Reset to defaults**. Changes take effect on the next page load.
- **Content** — one button per page. Tap a page to edit its text, press **+** to add a
  page (a new page starts as `<#-- title: New Page -->`), and **drag the buttons** to
  change the order in the menu. Emptying the title deletes the page.
- **Images** — the logo and photos that came from the old site, plus any new upload. An
  image is placed in a page with `<img src="/getImage/images/<filename>">`.
- **Quick Links**, **Obsidian Vault** and the product-category sections are for the
  webshop and documentation features and are normally left alone after a conversion.

Tell the customer three things: their login, that page texts are edited under
**Website → Content**, and that colours are under **Website → Colours**.

---

## 7. Step 5 — go live on the real domain

The site already answers on the real hostnames as soon as DNS points at the GrowERP
server — nothing further to configure in GrowERP. Point the A/CNAME records of
`example.com` and `www.example.com` at the server and arrange the TLS certificate the
same way as for any other hosted site.

Two things to know about hostnames:

- They are matched as **patterns over all stores**, and when two stores could both
  answer, the oldest entry wins. Keep them literal (`www.example.com`), never partial
  (`example`), or the new site may capture traffic meant for another store.
- The import refuses to start if a hostname is already taken, naming the store that has
  it. That is a protection, not a bug — see below.

---

## 8. Running the import again

The import can only create an owner once. A second run stops with:

```
Email admin@example.com is already registered, this website was already imported
```

and changes nothing. This is deliberate: it prevents a duplicate company being created
from the same file.

To change the site **after** it has been imported, edit the pages in the admin app
(§6). The data file is the starting point, not a live sync — later edits made in the
admin app are not written back to it.

To install the same file on a **different** backend (e.g. from test to production),
simply run the import there; the file is complete on its own.

---

## 9. Limits

- **Blog / news post lists** are not supported (see §3).
- **Web shop content** — products, prices and categories are not scraped. A converted
  site is a marketing site; add a catalogue afterwards in the admin app.
- **Forms** on the source site are not carried over. GrowERP has its own lead-capture
  forms (admin app → Website → Forms), which is what the contact page should use.
- **Exact visual copy is not the goal.** The pages are rebuilt in the GrowERP template
  so they stay consistent, responsive and themeable; they will not be pixel-identical
  to the original.

---

## 10. Troubleshooting

| Symptom | Cause | What to do |
|---|---|---|
| `Hostname www.example.com is already used by store X` | another store already claims that name — often an older import or demo data | remove the hostname from that store, or use different hostnames in the file |
| `Email … is already registered` | the file was already imported on this backend | nothing to do; edit the live site in the admin app instead |
| `ownerSpec.json missing or incomplete` | the `siteId` does not match the ids inside the file, or the file was hand-edited | check that `siteId` equals the prefix used in the file (e.g. `EXAMPLE` for `EXAMPLE_ROOT`) |
| `Unknown service name` from the assistant | its service list predates the backend start | use the `curl` call in §4, or restart the backend |
| Page shows raw `<#` or `${` text | a page fragment has broken template code | edit that page under Website → Content and remove the stray code |
| Logo missing, GrowERP logo shown instead | the logo record did not load, or the browser cached the old one | reload with cache disabled; check `/getLogo` returns an image |
| An image is broken on one page only | filename in the page does not match the uploaded image | compare with the names listed under Website → Images |
| Site answers on the test name but not the real domain | DNS not pointed at the server yet | check DNS first, then that the hostname is listed for the store |

---

*Related documents:*
*`docs/Website_Template_Definition.md` — the page, theme and styling contract used when
authoring pages (technical).*
*`.claude/skills/convert-website/SKILL.md` — the conversion procedure the skill follows.*
*`docs/GrowERP_User_Manual_Marketing_CRM.md` — capturing and working the leads the new
website produces.*
