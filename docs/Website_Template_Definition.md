# GrowERP Website Template Definition

**Purpose**: this document fully defines the GrowERP storefront website template so that a developer — or an LLM without repository access — can convert an existing website into a GrowERP-hosted site. The conversion output is:

1. One `.html.ftl` **content page per source page** (stored in the database, editable in the admin app's Website dialog), plus
2. One `websiteColor.json` **theme** (the "lumina" color map).

No template code deployment is needed: the pages and theme are plain data, loaded through the Website dialog in the GrowERP admin app or via a seed XML file.

---

## 1. Hosting model

- GrowERP (Moqui backend + PopRestStore component) serves **one website per product store**, matched by request hostname.
- Two built-in **template sets** exist: `legacy` (Bootstrap) and `modern` (Tailwind, dark "Lumina" design). The set is selected per store in the Website dialog (Template dropdown). **Converted sites target the `modern` set.**
- The template set always renders the page **chrome** around your content:
  - `root` — HTML head (Tailwind CDN, fonts, Material Symbols icons, per-store generated CSS, Google Analytics), global JS (dropdowns, dialogs, toast, search).
  - `navbar` — fixed glass header: logo, store name, menu (built automatically from your content pages' titles), and for commerce stores: shop categories, cart, login.
  - `footer` — logo, quick links (from content pages), company contact info, social icons.
- Your converted pages are **body-only HTML fragments** rendered full-width *between* the navbar and footer. Never author `<html>`, `<head>`, `<body>`, navbar, or footer markup.

## 2. Page-type matrix

| Page | URL | Conversion status |
|---|---|---|
| **Home** | `/` | **Mandatory** for a marketing-site conversion: a content page stored as `home.html.ftl` overrides the built-in home page |
| **Content page** | `/content/{path}` | **One per source page** (about, pricing, contact, …): `.html.ftl` fragment |
| Markdown page | `/content/{path}` | **Optional** alternative for text-heavy pages: markdown (`.md.ftl`), auto-styled and wrapped with a sidebar navigation |
| Apps overview | `/modules` | System-provided — do not author |
| Category / Product / Search | `/category/{id}`, `/product/{id}`, `/search/{term}` | System-provided e-commerce pages — do not author |
| Navbar / Footer / Error | — | System-provided — do not author; footer content is driven by company contact data and social URL settings |

### Content page rules (mandatory)

- **First line must be exactly**: `<#-- title: Your Page Title -->` — this title becomes the navbar menu entry, the footer quick-link label, and the page's name in the Website dialog.
- The home page's title should be `Home` (pages titled "home…" are excluded from the navbar menu).
- **Grouped menus (nested paths)**: a page path may contain one `/` (two levels, e.g. `products/pvc`). All pages sharing a first segment become a navbar **dropdown** named after that segment (`lakes_and_ponds` → "Lakes And Ponds"); if a page exists at exactly the group path (e.g. `products`), its title names the group and it becomes the dropdown's first entry. In the footer, group children are listed as individual quick links. Menu position of a group = position of its first member (by `sequenceNum`).
- **Hidden pages**: any path segment starting with `_` (e.g. `products/_pvc-spec`) makes the page routable at `/content/{path}` but excluded from the navbar and footer — use for detail/spec pages linked only from other pages.
- Body-only fragment; top-level wrapper should be `<main class="pt-28 pb-16"> … </main>` (`pt-28` clears the fixed navbar; use `pt-24` for the home page).
- Page sections within a page — recommended structure (all optional except one main section):
  - ambient background glows (decorative, optional)
  - hero section (headline, subtitle, call-to-action buttons)
  - feature/bento card grids
  - CTA band
- Markdown pages instead start with a `# Heading` on the first line (that heading is the title) and are automatically styled (`.prose-lumina`) with a generated sidebar.

## 3. Theme: the `websiteColor.json` contract

One JSON file per store. The **`lumina` map is the single color vocabulary** — it drives the modern template's full palette *and* the legacy template's header/footer colors (derived server-side from `surfaceContainerLowest`/`onSurface`). All 16 keys are required when providing a theme; values are `#rrggbb` hex:

```json
{
  "lumina": {
    "surface": "#0b1326",
    "surfaceContainerLowest": "#060e20",
    "surfaceContainerLow": "#131b2e",
    "surfaceContainer": "#171f33",
    "surfaceContainerHigh": "#222a3d",
    "surfaceContainerHighest": "#2d3449",
    "onSurface": "#dae2fd",
    "onSurfaceVariant": "#bccac0",
    "primary": "#68dba9",
    "onPrimary": "#003825",
    "primaryContainer": "#25a475",
    "secondary": "#4edea3",
    "tertiary": "#45dfa4",
    "error": "#ffb4ab",
    "outline": "#87948b",
    "outlineVariant": "#3d4a42"
  },
  "luminaScheme": "custom",
  "luminaBrightness": "dark",
  "TwitterUrl": "",
  "FacebookUrl": "",
  "InstagramUrl": "",
  "YouTubeUrl": "",
  "LinkedInUrl": "",
  "SubstackUrl": ""
}
```

- Token semantics follow Material 3: `surface*` = page/panel backgrounds from deepest (`surfaceContainerLowest`) to most elevated (`surfaceContainerHighest`); `onSurface`/`onSurfaceVariant` = text colors guaranteed readable on the surfaces; `primary` = brand/action color with `onPrimary` text; `secondary`/`tertiary` = supporting accents; `outline*` = borders.
- `luminaScheme` is bookkeeping for the admin theme picker (any string). `luminaBrightness` (`"dark"`|`"light"`) **is honored by the server**: it drives the browser `color-scheme`, the `theme-color` meta tag, the anti-FOUC background, and a server-derived `--l-contrast` channel variable (white on dark themes, black on light themes) used for the chrome's hairline borders and any `white`-named Tailwind utilities. Light themes therefore work end-to-end — supply a light `lumina` map **and** `"luminaBrightness": "light"`. `--l-contrast` is derived; do not add a `contrast` key to the `lumina` map.
- The six `*Url` keys populate footer social icons (empty string hides an icon).
- If the `lumina` map is omitted entirely, the server uses the default dark Lumina palette (the values shown above).
- The server converts hex to CSS `R G B` channel variables named `--l-surface`, `--l-primary`, etc. (kebab-case with `--l-` prefix), so Tailwind opacity modifiers work.

## 4. Styling contract (what classes to use in page fragments)

Tailwind utility classes with these **theme color names** (never hardcode hex colors in pages):

`surface`, `surface-container-lowest`, `surface-container-low`, `surface-container`, `surface-container-high`, `surface-container-highest`, `on-surface`, `on-surface-variant`, `primary`, `on-primary`, `primary-container`, `secondary`, `tertiary`, `error`, `outline`, `outline-variant`

Used as normal Tailwind utilities, opacity modifiers included: `bg-surface`, `text-on-surface-variant`, `bg-primary/10`, `border-outline-variant/30`, `text-primary`.

Additional provided helper classes:

| Class | Effect |
|---|---|
| `.l-glass` | glassmorphic panel: translucent surface + backdrop blur + subtle white border |
| `.l-glow` | primary-colored glow shadow (use on primary buttons) |
| `.l-gradient-text` | primary→tertiary gradient-clipped text (hero headline accents) |
| `.prose-lumina` | styles raw markdown/long-form HTML (headings, lists, tables, code) |

Other conventions:
- Fonts: `font-display` (Inter, headings), body default Inter, `font-label` (Geist, buttons/labels).
- Icons: Material Symbols — `<span class="material-symbols-outlined">icon_name</span>`; add class `icon-fill` for filled style.
- Layout: `max-w-container mx-auto px-4 md:px-12` (1440 px max), radius scale `rounded-lg/-xl/-2xl`.
- Native `<dialog>` elements and a `luminaToast(message, kind)` JS helper are pre-styled/pre-loaded.
- Standard component patterns (copy these shapes): primary button `bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-8 py-4 rounded-lg l-glow transition-all active:scale-95`; glass card `l-glass rounded-2xl p-8`; badge pill `inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface-container border border-outline-variant/50`.

## 5. URL contract (links available inside pages)

| URL | Meaning |
|---|---|
| `/` | home |
| `/content/{path}` | a content page (path = its wiki page path) |
| `/modules` | built-in apps/modules overview |
| `/category/{categoryId}`, `/product/{productId}`, `/search/{term}` | e-commerce pages (commerce stores only) |
| `/getLogo` | the store's logo image |
| `/assets/{file}` | static assets (favicon, images shipped with the server) |
| `/d#/checkout/{orgPartyId}`, `/d#/login/{orgPartyId}`, `/d#/account/create/{orgPartyId}` | customer app (cart/login/register) |
| `/logOut` | logout (GET form) |

External links (e.g. `https://admin.growerp.com` for sign-up CTAs) are fine. The navbar's Sign In link is automatically hidden on GrowERP's own marketing site.

## 6. FreeMarker context (optional dynamic data)

Pages are FreeMarker templates, so they *may* use dynamic values. For a static marketing conversion none are needed. Available (always guard with `!` defaults):

- `${storeInfo.productStore.storeName}`, `${storeInfo.productStore.productStoreId}`, `${storeInfo.productStore.organizationPartyId}`
- `storeInfo.menu` — list of `{title, path}` for the content pages (drives navbar/footer automatically)
- `storeInfo.categoryByType.{PsctBrowseRoot|PsctSearch|PsctPromotions|PsctFeatured|PsctNewProducts}` — store category ids/names
- `browseRootCategoryInfo.subCategoryList`, `promoProductList`, `featureProductList` — commerce data
- `partyDetail` — logged-in customer or null; `cartInfo.orderItemList` — cart lines
- `companyPostalAddress`, `companyPhone`, `companyEmailMech` — company contact records

## 7. FreeMarker safety rules (mandatory)

1. Any literal `${…}` in inline JavaScript or CSS must be wrapped in `<#noparse> … </#noparse>` — otherwise the server tries to interpolate it and errors.
2. **No JavaScript template literals (backticks)** in fragments that also use FreeMarker interpolation — use string concatenation.
3. Guard every dynamic value: `${storeInfo.productStore.storeName!''}`, `<#if partyDetail??> … </#if>`.
4. The title comment must be the exact form `<#-- title: X -->` on the first line.
5. HTML must be well-formed; the fragment is injected between header and footer as-is.

## 8. LLM conversion procedure

Given an existing website (URL or HTML dump), produce the conversion as follows:

1. **Inventory** the source site's pages; map each to the page-type matrix (§2). Merge or drop pages that correspond to system-provided routes (product listings, search). For sites with many pages, organize them into two-level groups (`products/pvc`, `applications/canals`) to get navbar dropdowns, and prefix rarely-visited detail pages with `_` to keep them out of the menus. **Known gaps** (not yet supported): dated blog/news post lists, and bulk page import (pages are registered one by one, or via a seed/demo XML file).
2. **Extract the brand palette** from the source site (background, text, brand/accent colors). Fill **all 16** lumina tokens (§3): choose `luminaBrightness`; derive the six `surface*` steps as a monotonic elevation ramp from the page background; pick `onSurface`/`onSurfaceVariant` with ≥ 7:1 / 4.5:1 contrast against the surfaces; map the brand color to `primary` (+ readable `onPrimary`), secondary accents to `secondary`/`tertiary`. Emit `websiteColor.json`.
3. **Author `home.html.ftl`**: `<#-- title: Home -->`, then hero (headline, subtitle, primary + secondary CTA), followed by the site's key selling-point sections as glass-card grids. Body-only, `<main class="pt-24 …">`.
4. **Author one `.html.ftl` per remaining page** (`<#-- title: X -->`, `<main class="pt-28 …">`), converting the source content into the styling contract (§4) — no hardcoded colors, no external CSS/JS, images either external URLs or uploaded via the Website dialog's image section.
5. **Register** the pages and theme, either:
   - **Website dialog** (admin app → Website): "+" in the content section with the FTL page type for each page; theme via the "Website theme" section (or paste colorJson); title, hostname, social URLs in their fields; **or**
   - **Seed XML** (for repeatable installs) — one block per page plus the color file, modeled on this pattern:

```xml
<moqui.resource.wiki.WikiPage wikiPageId="site_about" wikiSpaceId="YOUR_WS" pagePath="about"
    publishedVersionName="01" sequenceNum="3">
    <histories historySeqId="01" versionName="01" changeDateTime="1485028800000"/>
</moqui.resource.wiki.WikiPage>
<moqui.resource.DbResource filename="about.html.ftl" isFile="Y" resourceId="site_about"
    parentResourceId="your_content_dir">
    <file mimeType="text/html" versionName="01" rootVersionName="01">
        <fileData><![CDATA[<#-- title: About Us -->
<main class="pt-28 pb-16"> ... </main>]]></fileData>
        <histories versionName="01" versionDate="1485028800000" isDiff="N"/>
    </file>
</moqui.resource.DbResource>
```

   (`wikiSpaceId`/`parentResourceId` come from the store's wiki space and content directory; `sequenceNum` sets menu order; the color file is the same `DbResource` pattern with `filename="websiteColor.json"` and `mimeType="application/json"`.)

6. **Verify**: every route returns 200; view-source contains no raw `<#` or unresolved `${`; navbar menu lists all pages in order; theme contrast readable in both a wide and a 400-px viewport; mobile hamburger menu works.

---

*Worked examples: `backend/data/AntWebsysDemoData.xml` (dark theme, conversion of www.antwebsystems.com) and `backend/data/AccuGeoDemoData.xml` (light theme, grouped menus, hidden page — conversion of www.accugeo.com); load with `java -jar moqui.war load location=component://growerp/data/<file> no-run-es` and test with `curl -H 'Host: www.accugeo.com' http://localhost:8080/`.*

*Architecture references (for maintainers with repo access): template sets in `pop-rest-store/template/store/{legacy,modern}/`; set selection + theme pipeline in `pop-rest-store/screen/store.xml` (websiteColor.json → `styles.css.ftl` → per-store CSS with `--l-*` vars); content rendering in `screen/store/home.xml` and `screen/store/content.xml`; dialog backend `backend/service/growerp/100/WebsiteServices100.xml`; Flutter dialog `flutter/packages/growerp_website/.../website_dialog.dart`. The 16 lumina token names must stay in sync across `store.xml` (defaults), `styles.css.ftl` (emission), and `_luminaFromScheme` in the Flutter dialog.*
