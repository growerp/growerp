---
name: convert-website
description: Convert an existing company website into a GrowERP-hosted website for a new owner (tenant), including logo and page images. Use when the user says "convert this website", "scrape <site> into GrowERP", "import a website as a new owner", or gives a company URL to turn into a GrowERP site.
---

# Convert an external website into a new GrowERP owner

Scrape a company website, author it as a GrowERP `modern` (Lumina) template site, write
everything into ONE Moqui data file, and import that file to create a live, tenant-owned,
admin-app-editable website.

The full page/theme/styling contract is
[docs/Website_Template_Definition.md](../../../docs/Website_Template_Definition.md) — read it
before authoring pages. This skill only covers the conversion pipeline around it.

## Arguments

```
/convert-website <url> --admin-email <e> --admin-first <f> --admin-last <l>
                       --company-name <n> --currency <USD|EUR|...>
                       [--hostnames a.com,www.a.com] [--app AppAdmin]
```

Interview the user for anything missing. **Never use a scraped address as the admin login** —
that creates a login for a mailbox we do not control. The scraped contact email becomes the
company email only.

Pick a `<ID>`: uppercase, from the company name (`ACCUGEO`, `ANTWEBSYS`). It prefixes every
resource id in the file. Check it is free before generating:
`moqui_rest_call e1/moqui.resource.wiki.WikiSpace/<ID>_WS` must 404, and
`grep -rl '<ID>_ROOT' backend/data/` must be empty.

## 1. Scrape and inventory

```bash
curl -sL <url> -o /tmp/home.html                     # follow redirects
grep -oE 'href="[^"]*"' /tmp/home.html | sort -u     # route inventory
```

Single-page apps: download the JS bundle and mine it —
routes `grep -oE "path:['\"][^'\"]*"`, Vue text nodes
`perl -ne 'while (/t\._v\("([^"]{25,400})"\)/g) { print "$1\n" }'`,
colors `grep -oE '#[0-9a-fA-F]{6}' | sort | uniq -c | sort -rn`.

Map every page to the page-type matrix (doc §2). Drop pages covered by system routes
(product lists, search, cart). Organize many pages into two-level paths
(`products/pvc`, `applications/canals`) → one navbar dropdown per first segment. Detail/spec
pages get a `_` prefix on the leaf (`products/_pvc-spec`) → routable but hidden from menus.
Dated blog/news post lists are still **not supported** — convert posts to hidden pages plus a
manual index page, and tell the user.

## 2. Theme

Extract the palette from the source CSS. Fill **all 16** lumina tokens plus
`luminaBrightness` (`"dark"`/`"light"`) and the social `*Url` keys per doc §3. Never add a
`contrast` key.

## 3. Assets

```bash
curl -sL <imgUrl> -o /tmp/img/hero-plant.jpg
convert /tmp/img/hero-plant.jpg -resize '1600x1600>' -quality 82 /tmp/img/hero-plant.jpg  # if >300KB and ImageMagick present
base64 -w0 /tmp/img/hero-plant.jpg
```

Take the logo plus the images that actually carry meaning (hero, product, team) — not
sprites, icons or tracking pixels.

**Filename rules** (`/getImage` matches with SQL `LIKE '<path>%'`): lowercase, hyphens only,
**no `_` or `%`** (both are SQL wildcards), and no name may be a prefix of another
(`hero.jpg` + `hero-2.jpg` is fine, `hero.jpg` + `hero.jpg.webp` is not — the lookup takes an
arbitrary one of the two).

## 4. Author pages

Per doc §§2–7: first line exactly `<#-- title: X -->`, body-only,
`<main class="pt-28 pb-16">` (`pt-24` for home), token classes only (no hex), FreeMarker
safety rules (`<#noparse>` around literal `${}` in JS/CSS, no backticks). Text-heavy pages may
be `.md.ftl` (first line `# Title`, gets prose styling and a TOC sidebar).

Images are referenced as `<img src="/getImage/images/<filename>">`; the logo is `/getLogo`.
Footer contact details render automatically from the company's contact records — do not
hardcode them.

## 5. Generate `backend/data/<Name>OwnerImportData.xml`

`<entity-facade-xml type="demo">` (never auto-loaded at install). Content only — no Party,
ProductStore or ProductStoreSetting records; those are created at import time.

```xml
<!-- 1. directory tree; the root's filename must equal its resourceId -->
<moqui.resource.DbResource filename="<ID>_ROOT" isFile="N" resourceId="<ID>_ROOT" parentResourceId=""/>
<moqui.resource.DbResource filename="content" isFile="N" resourceId="<id>_content_dir" parentResourceId="<ID>_ROOT"/>
<moqui.resource.DbResource filename="images"  isFile="N" resourceId="<ID>_IMAGES"      parentResourceId="<ID>_ROOT"/>
<!-- one extra dir per two-level path group, parent = <id>_content_dir -->

<!-- 2. wiki space (no rootWikiPageId field — it does not exist) -->
<moqui.resource.wiki.WikiSpace wikiSpaceId="<ID>_WS" description="<Company> Website"
    allowAnyHtml="Y" rootPageLocation="dbresource://<ID>_ROOT"/>

<!-- 3. one pair per page; sequenceNum = menu order -->
<moqui.resource.wiki.WikiPage wikiPageId="<id>_about" wikiSpaceId="<ID>_WS" pagePath="about"
    publishedVersionName="01" sequenceNum="3">
    <histories historySeqId="01" versionName="01" changeDateTime="1485028800000"/>
</moqui.resource.wiki.WikiPage>
<moqui.resource.DbResource filename="about.html.ftl" isFile="Y" resourceId="<id>_about"
    parentResourceId="<id>_content_dir">
    <file mimeType="text/html" versionName="01" rootVersionName="01">
        <fileData><![CDATA[<#-- title: About -->
<main class="pt-28 pb-16"> ... </main>]]></fileData>
        <histories versionName="01" versionDate="1485028800000" isDiff="N"/>
    </file>
</moqui.resource.DbResource>

<!-- 4. images and logo, base64 in the CDATA -->
<moqui.resource.DbResource filename="logo.png" isFile="Y" resourceId="<ID>_LOGO" parentResourceId="<ID>_IMAGES"/>
<moqui.resource.DbResourceFile resourceId="<ID>_LOGO" rootVersionName="01" versionName="01" mimeType="image/png">
    <fileData><![CDATA[iVBORw0KGgo...]]></fileData>
</moqui.resource.DbResourceFile>

<!-- 5. theme, under the content dir -->
<moqui.resource.DbResource filename="websiteColor.json" isFile="Y" resourceId="<id>_website_color"
    parentResourceId="<id>_content_dir"> ... mimeType="application/json" ... </moqui.resource.DbResource>

<!-- 6. owner spec, directly under the root -->
<moqui.resource.DbResource filename="ownerSpec.json" isFile="Y" resourceId="<ID>_OWNER_SPEC"
    parentResourceId="<ID>_ROOT">
    <file mimeType="application/json" versionName="01" rootVersionName="01">
        <fileData><![CDATA[{
  "adminEmail": "...", "adminFirstName": "...", "adminLastName": "...",
  "companyName": "AccuGeo Liner, Inc.", "currencyId": "USD", "applicationId": "AppAdmin",
  "hostNames": ["www.accugeo.com", "accugeo.com", "accugeo.localhost:8080"],
  "logoPath": "images/logo.png",
  "contact": {
    "email": "info@accugeo.com",
    "telephone": {"countryCode": "1", "areaCode": "661", "contactNumber": "321-0447"},
    "address": {"address1": "321 Industrial St.", "city": "Bakersfield",
                "postalCode": "93307", "stateProvinceGeoId": "USA_CA", "countryGeoId": "USA"}
  }
}]]></fileData>
        <histories versionName="01" versionDate="1485028800000" isDiff="N"/>
    </file>
</moqui.resource.DbResource>
```

Gotchas that fail **silently**:
- `fileData` must be a nested element with CDATA. Bare text on the `<file>` element loads as
  NULL with no error.
- `publishedVersionName` must equal the file `versionName` **exactly** — `"01"`, not `"1"`.
- The root DbResource resolves by `filename`, not by `resourceId`; they must match.
- Keep `hostNames` literal — the value is used as a **regex** and the oldest matching row over
  all stores wins. Always include a `<name>.localhost:8080` entry for local testing.
- Verify `stateProvinceGeoId`/`countryGeoId` exist:
  `moqui_rest_call e1/moqui.basic.Geo/USA_CA`. A wrong id aborts the import with an FK error.

## 6. Import

Backend must be running.

```
mcp__moqui__moqui_execute_service
  serviceName: growerp.100.ImportExportServices100.import#WebsiteOwner
  parameters:  {location: 'component://growerp/data/<Name>OwnerImportData.xml',
                siteId: '<ID>', password: '<chosen or omit for a random one>'}
```

If the MCP server answers "Unknown service name", its service list predates the backend
start — call the service over the Moqui tools endpoint instead (same result, works without a
restart):

```bash
curl -s -u SystemSupport:moqui -X POST \
  'http://localhost:8080/apps/tools/Service/ServiceRun/runJson' \
  --data-urlencode 'serviceName=growerp.100.ImportExportServices100.import#WebsiteOwner' \
  --data-urlencode 'location=component://growerp/data/<Name>OwnerImportData.xml' \
  --data-urlencode 'siteId=<ID>' --data-urlencode 'password=<chosen>'
```

The service loads the file, creates the owner with `create#Tenant` + `complete#TenantSetup`,
repoints the new store at `<ID>_WS` / `dbresource://<ID>_ROOT` with `PsstTemplateId=modern`,
adds the hostnames, links the logo and registers every image under `<ID>_IMAGES`.

Report `ownerPartyId`, `companyPartyId`, `productStoreId` and the **password** back to the
user — it is not recoverable afterwards.

The import runs once per owner: a second run stops with "already registered" and changes
nothing. To re-import content into an existing tenant, edit the pages in the admin app's
Website dialog instead.

## 7. Verify

```bash
H='Host: www.accugeo.com'
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/            # 200
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/content/about
curl -s -H "$H" http://localhost:8080/ | grep -E '<#|\$\{'                          # empty
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/getLogo      # 200
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" http://localhost:8080/getImage/images/logo.png
curl -s http://localhost:8080/components/styles/<productStoreId>.css | grep -- '--l-contrast'
```

Check every route from the inventory, that hidden `_` pages are absent from the navbar markup,
that the dropdown count matches the path groups, and that pre-existing stores still resolve on
their own hostnames. Then log in to the admin app with the admin email and the returned
password: the Website dialog must list all pages, and the company must show the scraped
address, phone and logo.
