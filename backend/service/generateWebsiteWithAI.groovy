/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Turn scraped website data into a GrowERP owner-import XML document: the same shape the
 * /convert-website skill produces (see docs/Website_Template_Definition.md and
 * .claude/skills/convert-website/SKILL.md), ready for import#WebsiteOwner.
 *
 * Two Gemini calls shapes are used: one for the site structure plus theme, then one per page
 * for its HTML body — a single whole-site call would run past maxOutputTokens and truncate.
 *
 * In:  siteData (from scrapeWebsite.groovy), siteId, companyName, adminEmail, adminFirstName,
 *      adminLastName, currencyId, applicationId, hostNames (List), apiKey, ownerPartyId
 * Out: xmlText, pageCount, imageCount
 */

import groovy.json.JsonOutput
import org.jsoup.Jsoup
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

final String USER_AGENT = 'Mozilla/5.0 (compatible; GrowERP-WebsiteGenerator/1.0; +https://www.growerp.com)'
final long MAX_IMAGE_BYTES = 2 * 1024 * 1024

def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
// the structure call returns real structured data, so JSON mode fits there
Map aiOptions = [apiKey: apiKey, ownerPartyId: ownerPartyId, jsonMode: true,
                 temperature: 0.4, maxOutputTokens: 8192]
// page bodies come back as plain text, see extractBody below
Map pageOptions = aiOptions + [jsonMode: false]

// --------------------------------------------------------------------------------------
// helpers
// --------------------------------------------------------------------------------------

/** lowercase-hyphen file name, no _ or % (both are LIKE wildcards in the /getImage lookup). */
def safeFileName = { String name, String fallback ->
    String base = (name ?: '').toLowerCase().replaceAll(/[^a-z0-9.]+/, '-')
        .replaceAll(/-+/, '-').replaceAll(/^-|-$/, '')
    if (!base || base.startsWith('.')) base = fallback
    return base
}

def cdata = { String text -> "<![CDATA[${(text ?: '').replace(']]>', ']]]]><![CDATA[>')}]]>" }

/** models like to wrap their answer in a ``` fence even when told not to */
def stripFences = { String text ->
    String t = (text ?: '').trim()
    t = t.replaceAll(/(?s)^```[a-zA-Z]*\s*/, '').replaceAll(/(?s)\s*```$/, '')
    return t.trim()
}

/**
 * The page body comes back as raw text, not wrapped in JSON: a 4kB HTML fragment full of
 * class="..." attributes is exactly what a model fails to escape, and one unescaped quote
 * ends the JSON string early and breaks the whole parse. Keep only the fragment itself in
 * case the model adds a sentence around it.
 */
def extractBody = { String text, boolean isMd ->
    String t = stripFences(text)
    if (!isMd) {
        int start = t.indexOf('<main')
        int end = t.lastIndexOf('</main>')
        if (start >= 0 && end > start) t = t.substring(start, end + '</main>'.length())
    }
    return t.trim()
}

/** entity id columns are 40 chars; longer generated ids abort the whole import */
def shortId = { String value -> value.length() > 40 ? value.substring(0, 40) : value }

def xmlAttr = { String text ->
    (text ?: '').replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
}

try {
    String id = (siteId as String).toUpperCase()
    String low = id.toLowerCase()
    Map site = siteData as Map

    // ----------------------------------------------------------------------------------
    // 1. structure and theme
    // ----------------------------------------------------------------------------------
    List pageSummaries = (site.pages as List).collect { p ->
        [path: p.path, title: p.title, headings: (p.headings as List)?.take(12),
         text: ((p.text ?: '') as String).take(1500)]
    }
    String structurePrompt = """
You are converting an existing company website to the GrowERP 'modern' (Lumina) website template.

COMPANY: ${companyName}
SOURCE SITE: ${site.homeUrl} — "${site.siteTitle}"
DESCRIPTION: ${site.siteDescription ?: ''}
DOMINANT COLOURS FOUND (most used first): ${JsonOutput.toJson(site.colors)}
${site.isSinglePageApp ? "This is a single page app; the text below was mined from its JS bundle:\n" + JsonOutput.toJson((site.bundleText as List)?.take(120)) : ''}
SOURCE PAGES:
${JsonOutput.toJson(pageSummaries)}

Decide the page structure and the colour theme for the new site.

PAGE RULES
- Always include exactly one page with pagePath "home" and sequenceNum 1.
- Merge or drop source pages that an e-commerce system provides itself (product listings,
  search, cart, login, sitemap).
- Use a two level pagePath like "products/pvc" or "applications/canals" to group related
  pages: each first segment becomes one navbar dropdown. Only group when there are 2 or more
  pages in that group.
- Prefix the last segment with "_" for rarely visited detail or specification pages: they stay
  reachable by link but are hidden from the menus.
- Return AT MOST ${pageSummaries.size()} pages, one per source page. You may merge source pages
  or drop them, never invent a page there is no source material for: an empty page the company
  has to delete again is worse than no page.
- Use "md" as pageType for text-only pages (privacy, terms, long articles) and "html" for
  everything else.

THEME RULES
- Fill all 16 lumina tokens. Values are CSS colours (hex).
- luminaBrightness is "dark" or "light" and must match the surfaces.
- surface..surfaceContainerHighest is a monotonic elevation ramp starting at the page
  background. onSurface must have at least 7:1 contrast against surface, onSurfaceVariant at
  least 4.5:1. primary is the brand colour, onPrimary must be readable on it.

Return ONLY JSON:
{
  "pages": [{"pagePath":"home","title":"Home","pageType":"html","sequenceNum":1,
             "sourceUrl":"<the source page url this is based on, or empty>",
             "purpose":"<one sentence on what this page must convey>",
             "metaDescription":"<one sentence of at most 155 characters describing this page for search engines and AI readers>"}],
  "theme": {"luminaBrightness":"light","primary":"#...","onPrimary":"#...","secondary":"#...",
            "onSecondary":"#...","tertiary":"#...","onTertiary":"#...","error":"#...",
            "onError":"#...","surface":"#...","surfaceContainerLowest":"#...",
            "surfaceContainerLow":"#...","surfaceContainer":"#...","surfaceContainerHigh":"#...",
            "surfaceContainerHighest":"#...","onSurface":"#...","onSurfaceVariant":"#...",
            "outlineVariant":"#..."},
  "logoUrl": "<the url from the candidates that is most likely the company logo, or empty>",
  "images": [{"url":"<content image url worth keeping>","alt":"...","usedOnPagePath":"..."}]
}
LOGO CANDIDATES: ${JsonOutput.toJson(site.logoCandidates)}
IMAGES FOUND: ${JsonOutput.toJson((site.images as List)?.take(30))}
"""
    ec.logger.info("generateWebsiteWithAI: asking for the structure of ${site.homeUrl}")
    String structureText = GeminiAiUtil.callGeminiApi(ec, structurePrompt, aiOptions)
    def structure
    try {
        structure = GeminiAiUtil.parseJsonResponse(structureText)
    } catch (Exception e) {
        ec.logger.warn("generateWebsiteWithAI: unparsable structure answer:\n${structureText?.take(2000)}")
        throw new Exception("the model did not return usable JSON for the site structure: ${e.message}")
    }
    List aiPages = (structure.pages ?: []) as List
    if (!aiPages) throw new Exception("the model returned no pages for ${site.homeUrl}")
    // the model sometimes ignores the limit and invents pages with no source behind them
    if (aiPages.size() > pageSummaries.size()) {
        ec.logger.warn("generateWebsiteWithAI: model returned ${aiPages.size()} pages for " +
            "${pageSummaries.size()} source pages, keeping the first ${pageSummaries.size()}")
        aiPages = aiPages.take(pageSummaries.size())
    }
    Map theme = (structure.theme ?: [:]) as Map

    // ----------------------------------------------------------------------------------
    // 2. images: logo first, then the content images the model kept. Done before the page
    //    bodies so the pages can reference the real file names.
    // ----------------------------------------------------------------------------------
    List downloaded = []
    Set usedNames = new HashSet()
    def download = { String url, String preferredName ->
        try {
            def res = Jsoup.connect(url).userAgent(USER_AGENT).timeout(20000)
                .maxBodySize((int) MAX_IMAGE_BYTES).ignoreContentType(true).execute()
            byte[] bytes = res.bodyAsBytes()
            String mime = res.contentType()?.split(';')?.first()?.trim()
            if (!bytes || bytes.length < 1024 || !mime?.startsWith('image/')) return null
            String ext = mime.replace('image/', '').replace('jpeg', 'jpg').replace('svg+xml', 'svg')
            String base = safeFileName(preferredName, "image-${downloaded.size() + 1}")
            if (base.contains('.')) base = base.substring(0, base.lastIndexOf('.'))
            String name = "${base}.${ext}"
            // no name may be a prefix of another: /getImage matches with LIKE 'name%'
            int n = 2
            while (usedNames.any { it == name || it.startsWith(base) && it != name }) {
                base = "${base}-${n++}"; name = "${base}.${ext}"
                if (n > 20) break
            }
            usedNames.add(name)
            return [name: name, mime: mime, base64: bytes.encodeBase64().toString(), url: url]
        } catch (Exception e) {
            ec.logger.info("generateWebsiteWithAI: image skipped ${url}: ${e.message}")
            return null
        }
    }

    String logoUrl = (structure.logoUrl as String) ?: ((site.logoCandidates as List)?.find { true } as String)
    Map logo = logoUrl ? download(logoUrl, 'logo') : null
    if (logo) downloaded.add(logo)
    ((structure.images ?: []) as List).take(8).each { Map img ->
        String url = img.url as String
        if (!url || url == logoUrl) return
        Map d = download(url, (img.alt as String) ?: url.tokenize('/').last())
        if (d) downloaded.add(d)
    }
    String imageList = JsonOutput.toJson(downloaded.findAll { it != logo }.collect { it.name })

    // ----------------------------------------------------------------------------------
    // 3. one call per page for the body; a single whole-site call would hit maxOutputTokens
    // ----------------------------------------------------------------------------------
    Map sourceByUrl = [:]
    (site.pages as List).each { sourceByUrl[it.url as String] = it }

    List pageBodies = []
    aiPages.eachWithIndex { Map p, int idx ->
        Map source = (Map) sourceByUrl[p.sourceUrl as String]
        String pagePath = (p.pagePath as String) ?: "page${idx}"
        boolean isMd = (p.pageType == 'md')
        String pageTitle = (p.title as String) ?: pagePath
        String sourceText = ((source?.text ?: '') as String).take(6000)

        String pagePrompt = isMd ? """
Write the content of the "${pageTitle}" page of ${companyName}'s website as Markdown.
PURPOSE: ${p.purpose ?: ''}
SOURCE TEXT:
${sourceText}

RULES
- First line exactly: # ${pageTitle}
- Plain Markdown only: headings, paragraphs, lists, links. No HTML, no front matter.
- Keep the facts of the source text. Never invent prices, certifications or claims.
Return ONLY the Markdown itself: no JSON, no ``` fence, no explanation before or after.
""" : """
Write the body of the "${pageTitle}" page of ${companyName}'s website for the GrowERP 'modern'
Lumina template.
PURPOSE: ${p.purpose ?: ''}
SOURCE PAGE: ${p.sourceUrl ?: ''}
SOURCE HEADINGS: ${JsonOutput.toJson(source?.headings ?: [])}
SOURCE TEXT:
${sourceText}
SOURCE LIST ITEMS: ${JsonOutput.toJson((source?.listItems ?: []).take(30))}
IMAGES YOU MAY USE, reference as <img src="/getImage/images/FILENAME">: ${imageList}

MANDATORY RULES
- Output a body fragment only: start with <main class="${idx == 0 ? 'pt-24' : 'pt-28'} pb-16"> and
  end with </main>. No <html>, <head>, <body>, <script>, <style> or external css/js.
- Use ONLY these token classes for colour, never hex values or tailwind palette names:
  bg-surface, bg-surface-container, bg-surface-container-high, bg-primary, bg-secondary,
  bg-tertiary, text-on-surface, text-on-surface-variant, text-on-primary, text-primary,
  border-outline-variant, and the helpers l-glass, l-glow, l-gradient-text.
- Layout wrapper for every section: <section class="max-w-container mx-auto px-4 md:px-12 py-8">
- Cards: <div class="l-glass rounded-2xl p-8">. Primary button:
  <a class="bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-8 py-4 rounded-lg l-glow transition-all active:scale-95">
- Icons only as <span class="material-symbols-outlined">icon_name</span>.
- Internal links are /content/<pagePath>, the home page is /.
- NEVER write a dollar sign followed by a brace, and never a backtick: the page is rendered as
  a FreeMarker template and those would break it.
- Do not put the company address, phone or email in the page: the template renders those in
  the footer automatically.
- Keep the facts of the source text. Never invent prices, certifications or claims.
${idx == 0 ? '- This is the home page: open with a hero (headline, one sentence subtitle, a primary and a secondary call to action), then the key selling points as a card grid.' : ''}
Return ONLY the HTML itself, starting with <main and ending with </main>: no JSON, no ```
fence, no explanation before or after.
"""
        ec.logger.info("generateWebsiteWithAI: writing page ${pagePath}")
        String raw = GeminiAiUtil.callGeminiApi(ec, pagePrompt, pageOptions)
        String body = extractBody(raw, isMd)
        if (!body) throw new Exception("the model returned no content for page ${pagePath}")
        pageBodies.add([pagePath: pagePath, title: pageTitle, isMd: isMd,
                        metaDescription: (p.metaDescription as String)?.replace('-->', '')?.trim(),
                        sequenceNum: (p.sequenceNum ?: (idx + 1)) as int, body: body])
    }

    // ----------------------------------------------------------------------------------
    // 4. assemble the owner-import xml
    // ----------------------------------------------------------------------------------
    long stamp = System.currentTimeMillis()
    StringBuilder xml = new StringBuilder()
    xml.append('<?xml version="1.0" encoding="UTF-8"?>\n')
    xml.append("<!-- ${xmlAttr(companyName as String)} website, generated from ${xmlAttr(site.homeUrl as String)}\n")
    xml.append("     by the GrowERP website generator. Installed with import#WebsiteOwner. -->\n")
    xml.append('<entity-facade-xml type="demo">\n\n')

    // directories: the root resolves by filename, so filename must equal its resourceId
    xml.append("""    <moqui.resource.DbResource filename="${id}_ROOT" isFile="N" resourceId="${id}_ROOT" parentResourceId=""/>\n""")
    xml.append("""    <moqui.resource.DbResource filename="content" isFile="N" resourceId="${low}_content_dir" parentResourceId="${id}_ROOT"/>\n""")
    xml.append("""    <moqui.resource.DbResource filename="images" isFile="N" resourceId="${id}_IMAGES" parentResourceId="${id}_ROOT"/>\n""")

    Set groups = new LinkedHashSet()
    pageBodies.each { Map p ->
        List parts = (p.pagePath as String).tokenize('/')
        if (parts.size() > 1) groups.add(parts[0])
    }
    groups.each { String g ->
        String dirId = shortId("${low}_${g.replaceAll(/[^a-z0-9]/, '')}_dir")
        xml.append("""    <moqui.resource.DbResource filename="${g}" isFile="N" resourceId="${dirId}" parentResourceId="${low}_content_dir"/>\n""")
    }

    xml.append("""\n    <moqui.resource.wiki.WikiSpace wikiSpaceId="${id}_WS" description="${xmlAttr(companyName as String)} Website Content"\n""")
    xml.append("""        allowAnyHtml="Y" rootPageLocation="dbresource://${id}_ROOT"/>\n\n""")

    pageBodies.eachWithIndex { Map p, int i ->
        String pagePath = p.pagePath as String
        List parts = pagePath.tokenize('/')
        String leaf = parts.last()
        String parentDir = parts.size() > 1 ?
            shortId("${low}_${parts[0].replaceAll(/[^a-z0-9]/, '')}_dir") : "${low}_content_dir"
        // the index keeps it unique even after the 40 char cut
        String pageId = shortId("${low}_${i}_${pagePath.replaceAll(/[^a-zA-Z0-9]/, '_')}")
        String fileName = "${leaf}.${p.isMd ? 'md' : 'html'}.ftl"
        String mime = p.isMd ? 'text/markdown' : 'text/html'
        String body = (p.body as String).trim()
        String header = p.isMd ? '' : "<#-- title: ${p.title} -->\n"
        if (p.isMd && !body.startsWith('#')) header = "# ${p.title}\n\n"
        // seo/AI description front matter, read back by get#StoreInfo and the store.xml pre-actions
        if (p.metaDescription) header = (p.isMd ? "<!-- description: ${p.metaDescription} -->\n"
                : "<#-- description: ${p.metaDescription} -->\n") + header

        xml.append("""    <moqui.resource.wiki.WikiPage wikiPageId="${pageId}" wikiSpaceId="${id}_WS" pagePath="${xmlAttr(pagePath)}"\n""")
        xml.append("""        publishedVersionName="01" sequenceNum="${p.sequenceNum}">\n""")
        xml.append("""        <histories historySeqId="01" versionName="01" changeDateTime="${stamp}"/>\n""")
        xml.append("""    </moqui.resource.wiki.WikiPage>\n""")
        xml.append("""    <moqui.resource.DbResource filename="${fileName}" isFile="Y" resourceId="${pageId}"\n""")
        xml.append("""        parentResourceId="${parentDir}">\n""")
        xml.append("""        <file mimeType="${mime}" versionName="01" rootVersionName="01">\n""")
        xml.append("""            <fileData>${cdata(header + body)}</fileData>\n""")
        xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
        xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")
    }

    // theme
    Map themeOut = [:]
    ['luminaBrightness', 'primary', 'onPrimary', 'secondary', 'onSecondary', 'tertiary',
     'onTertiary', 'error', 'onError', 'surface', 'surfaceContainerLowest', 'surfaceContainerLow',
     'surfaceContainer', 'surfaceContainerHigh', 'surfaceContainerHighest', 'onSurface',
     'onSurfaceVariant', 'outlineVariant'].each { k -> if (theme[k]) themeOut[k] = theme[k] }
    xml.append("""    <moqui.resource.DbResource filename="websiteColor.json" isFile="Y" resourceId="${low}_website_color"\n""")
    xml.append("""        parentResourceId="${low}_content_dir">\n""")
    xml.append("""        <file mimeType="application/json" versionName="01" rootVersionName="01">\n""")
    xml.append("""            <fileData>${cdata(JsonOutput.prettyPrint(JsonOutput.toJson(themeOut)))}</fileData>\n""")
    xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
    xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")

    // images
    downloaded.eachWithIndex { Map img, int i ->
        String resId = "${id}_IMG_${i}"
        xml.append("""    <moqui.resource.DbResource filename="${img.name}" isFile="Y" resourceId="${resId}"\n""")
        xml.append("""        parentResourceId="${id}_IMAGES"/>\n""")
        xml.append("""    <moqui.resource.DbResourceFile resourceId="${resId}" rootVersionName="01"\n""")
        xml.append("""        versionName="01" mimeType="${img.mime}">\n""")
        xml.append("""        <fileData><![CDATA[${img.base64}]]></fileData>\n""")
        xml.append("""    </moqui.resource.DbResourceFile>\n""")
    }

    // owner spec, read back by import#WebsiteOwner
    Map contact = [:]
    List foundEmails = ((site.contact?.emails ?: []) as List)
    if (foundEmails) contact.email = foundEmails[0]
    List foundPhones = ((site.contact?.phones ?: []) as List)
    if (foundPhones) {
        contact.telephone = [countryCode: '', areaCode: '',
                             contactNumber: (foundPhones[0] as String).replaceAll(/[^0-9+ -]/, '')]
    }
    Map spec = [adminEmail: adminEmail, adminFirstName: adminFirstName ?: 'Site',
                adminLastName: adminLastName ?: 'Administrator',
                companyName: companyName, currencyId: currencyId,
                applicationId: applicationId ?: 'AppAdmin',
                hostNames: hostNames ?: [], sourceUrl: site.homeUrl]
    if (logo) spec.logoPath = "images/${logo.name}"
    if (contact) spec.contact = contact
    xml.append("""\n    <moqui.resource.DbResource filename="ownerSpec.json" isFile="Y"\n""")
    xml.append("""        resourceId="${id}_OWNER_SPEC" parentResourceId="${id}_ROOT">\n""")
    xml.append("""        <file mimeType="application/json" versionName="01" rootVersionName="01">\n""")
    xml.append("""            <fileData>${cdata(JsonOutput.prettyPrint(JsonOutput.toJson(spec)))}</fileData>\n""")
    xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
    xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")
    xml.append('</entity-facade-xml>\n')

    xmlText = xml.toString()
    pageCount = pageBodies.size()
    imageCount = downloaded.size()
    ec.logger.info("generateWebsiteWithAI: ${id} -> ${pageCount} pages, ${imageCount} images, ${xmlText.length()} chars")
} catch (Exception e) {
    ec.logger.error("generateWebsiteWithAI failed: ${e.message}", e)
    ec.message.addError("Website generation failed: ${e.message}")
}
