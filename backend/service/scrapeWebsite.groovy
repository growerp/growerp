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
 * Scrape a public website with Jsoup (on the classpath via the framework, see
 * moqui/framework/build.gradle) so the website generator has structured input for the AI
 * page authoring.
 *
 * In:  sourceUrl (required), maxPages (default 12)
 * Out: siteData Map [homeUrl, host, siteTitle, siteDescription, pages, images,
 *                    logoCandidates, colors, contact, isSinglePageApp, bundleText]
 *
 * Called from WebsiteGeneratorServices100.process#WebsiteConversion.
 *
 * NOTE everything is a closure, not a method: methods in a Groovy script cannot see the
 * script's local variables, closures can.
 */

import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

final String USER_AGENT = 'Mozilla/5.0 (compatible; GrowERP-WebsiteGenerator/1.0; +https://www.growerp.com)'
final int TIMEOUT_MS = 15000
final int MAX_BODY = 3 * 1024 * 1024
final List ASSET_SUFFIXES = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.pdf', '.zip',
                             '.css', '.js', '.ico', '.xml', '.mp4', '.doc', '.docx']

int pageLimit = (maxPages ?: 12) as int

def fetchDoc = { String url ->
    try {
        return Jsoup.connect(url).userAgent(USER_AGENT).timeout(TIMEOUT_MS)
            .maxBodySize(MAX_BODY).followRedirects(true).get()
    } catch (Exception e) {
        // older sites often have no or a broken certificate
        if (!url.startsWith('https://')) throw e
        return Jsoup.connect(url.replaceFirst('https://', 'http://')).userAgent(USER_AGENT)
            .timeout(TIMEOUT_MS).maxBodySize(MAX_BODY).followRedirects(true).get()
    }
}

def fetchText = { String url ->
    Jsoup.connect(url).userAgent(USER_AGENT).timeout(TIMEOUT_MS).maxBodySize(MAX_BODY)
        .ignoreContentType(true).ignoreHttpErrors(true).execute().body()
}

/** robots.txt disallow prefixes that apply to us, best effort. */
def readRobotsDisallow = { String origin ->
    List disallowed = []
    try {
        boolean applies = false
        fetchText(origin + '/robots.txt').readLines().each { String line ->
            String l = line.trim()
            if (l.toLowerCase().startsWith('user-agent:')) {
                String agent = l.substring(11).trim().toLowerCase()
                applies = (agent == '*' || agent.contains('growerp'))
            } else if (applies && l.toLowerCase().startsWith('disallow:')) {
                String path = l.substring(9).trim()
                if (path) disallowed.add(path)
            }
        }
    } catch (Exception e) {
        ec.logger.info("scrapeWebsite: no usable robots.txt at ${origin}: ${e.message}")
    }
    return disallowed
}

/** Readable page content; the headings carry the structure the model needs. */
def extractPage = { Document doc, String url ->
    doc.select('script, style, noscript, svg, iframe').remove()
    List headings = doc.select('h1, h2, h3').collect { "${it.tagName()}: ${it.text()}" }
        .findAll { it.length() > 4 }.take(40)
    String text = doc.body()?.text() ?: ''
    if (text.length() > 12000) text = text.substring(0, 12000)
    String path = '/'
    try { path = new URL(url).path ?: '/' } catch (Exception ignored) { }
    return [url: url, path: path, title: doc.title(),
            description: doc.select('meta[name=description]').attr('content'),
            headings: headings, text: text,
            listItems: doc.select('li').collect { it.text() }
                .findAll { it.length() > 10 && it.length() < 300 }.take(60)]
}

try {
    String startUrl = (sourceUrl as String).trim()
    if (!startUrl.startsWith('http')) startUrl = 'https://' + startUrl

    Document home = fetchDoc(startUrl)
    URL homeUrl = new URL(home.location())
    String host = homeUrl.host
    String origin = "${homeUrl.protocol}://${host}"
    List disallowed = readRobotsDisallow(origin)

    // ---- link inventory: same host, real pages only --------------------------------------
    List queue = [home.location()]
    home.select('a[href]').each { link ->
        String abs = link.absUrl('href')
        if (!abs || !abs.startsWith('http')) return
        abs = abs.replaceFirst(/#.*$/, '').replaceFirst(/\/$/, '')
        URL u
        try { u = new URL(abs) } catch (Exception ignored) { return }
        if (u.host != host) return
        String lower = (u.path ?: '').toLowerCase()
        if (ASSET_SUFFIXES.any { lower.endsWith(it) }) return
        if (disallowed.any { u.path?.startsWith(it) }) return
        if (!queue.contains(abs)) queue.add(abs)
    }

    // ---- fetch the pages -------------------------------------------------------------------
    List pages = []
    List docs = []
    queue.take(pageLimit).eachWithIndex { String url, int i ->
        try {
            Document doc = (i == 0) ? home : fetchDoc(url)
            docs.add(doc)
            pages.add(extractPage(doc.clone() as Document, url))
            if (i > 0) Thread.sleep(400) // be a polite guest on someone else's server
        } catch (Exception e) {
            ec.logger.warn("scrapeWebsite: skipping ${url}: ${e.message}")
        }
    }

    // ---- images ----------------------------------------------------------------------------
    List images = []
    Set seenImg = new HashSet()
    docs.each { Document doc ->
        doc.select('img[src]').each { img ->
            String abs = img.absUrl('src')
            if (!abs || !abs.startsWith('http') || !seenImg.add(abs)) return
            String w = img.attr('width').replaceAll(/[^0-9]/, '')
            images.add([url: abs, alt: img.attr('alt'),
                        width: w.isInteger() ? (w as int) : 0, onPage: doc.location()])
        }
    }

    // logo candidates: declared icons, og:image, then anything named like a logo
    List logoCandidates = []
    home.select('link[rel~=(?i)icon], link[rel~=(?i)apple-touch-icon]').each {
        String abs = it.absUrl('href'); if (abs) logoCandidates.add(abs)
    }
    String ogImage = home.select('meta[property=og:image]').attr('abs:content') ?:
        home.select('meta[property=og:image]').attr('content')
    if (ogImage?.startsWith('http')) logoCandidates.add(ogImage)
    images.each {
        if ("${it.url} ${it.alt}".toLowerCase().contains('logo')) logoCandidates.add(it.url as String)
    }

    // ---- colours: inline styles, style blocks and the linked stylesheets ---------------------
    Map colorCount = [:]
    def countColors = { String css ->
        if (!css) return
        (css =~ /#[0-9a-fA-F]{6}\b/).each { m ->
            String c = (m as String).toLowerCase(); colorCount[c] = (colorCount[c] ?: 0) + 1
        }
        (css =~ /rgba?\([0-9\s,.%]+\)/).each { m ->
            String c = m as String; colorCount[c] = (colorCount[c] ?: 0) + 1
        }
    }
    docs.each { Document doc ->
        doc.select('[style]').each { countColors(it.attr('style')) }
        doc.select('style').each { countColors(it.data()) }
    }
    home.select('link[rel=stylesheet]').take(4).each { sheet ->
        try { countColors(fetchText(sheet.absUrl('href'))) }
        catch (Exception e) { ec.logger.info("scrapeWebsite: stylesheet skipped: ${e.message}") }
    }
    List topColors = colorCount.sort { -it.value }.take(20).collect { [color: it.key, count: it.value] }

    // ---- contact details for the company record ----------------------------------------------
    Set emails = new LinkedHashSet(), phones = new LinkedHashSet()
    List addresses = []
    docs.each { Document doc ->
        doc.select('a[href^=mailto:]').each {
            emails.add(it.attr('href').replace('mailto:', '').split('\\?')[0])
        }
        doc.select('a[href^=tel:]').each { phones.add(it.attr('href').replace('tel:', '')) }
        doc.select('address, footer').each {
            String t = it.text(); if (t && t.length() < 400) addresses.add(t)
        }
    }
    // older sites write their contact details as plain text instead of mailto:/tel: links
    if (!emails || !phones) {
        String allText = pages.collect { it.text }.join(' ')
        if (!emails) {
            (allText =~ /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/).each { emails.add(it as String) }
        }
        if (!phones) {
            (allText =~ /(\(?\d{3}\)?[\s.-]){1,2}\d{3}[\s.-]\d{4}/).each { m ->
                phones.add(((m instanceof List ? m[0] : m) as String).trim())
            }
        }
    }

    // ---- single page app: the html body is empty, the content lives in the bundle -------------
    boolean spa = pages && pages.every { ((it.text ?: '') as String).length() < 200 }
    List bundleText = []
    if (spa) {
        ec.logger.info("scrapeWebsite: ${startUrl} looks like a single page app, mining its bundles")
        home.select('script[src]').take(3).each { script ->
            try {
                String js = fetchText(script.absUrl('src'))
                (js =~ /path\s*:\s*['"]([^'"]{1,60})['"]/).each { m -> bundleText.add("route: ${m[1]}") }
                (js =~ /"([^"\\]{40,400})"/).each { m ->
                    String s = m[1]
                    if (s ==~ /.*[a-zA-Z]{3,}\s+[a-zA-Z]{3,}.*/ && !s.contains('function')) bundleText.add(s)
                }
            } catch (Exception e) {
                ec.logger.info("scrapeWebsite: bundle skipped: ${e.message}")
            }
        }
        bundleText = bundleText.unique().take(300)
    }

    siteData = [
        homeUrl: home.location(),
        host: host,
        siteTitle: home.title(),
        siteDescription: home.select('meta[name=description]').attr('content'),
        pages: pages,
        images: images.take(40),
        logoCandidates: logoCandidates.unique().take(8),
        colors: topColors,
        contact: [emails: emails.toList().take(3), phones: phones.toList().take(3),
                  addressBlocks: addresses.take(5)],
        isSinglePageApp: spa,
        bundleText: bundleText,
    ]
    ec.logger.info("scrapeWebsite: ${startUrl} -> ${pages.size()} pages, ${images.size()} images, spa=${spa}")
} catch (Exception e) {
    ec.logger.error("scrapeWebsite failed for ${sourceUrl}: ${e.message}", e)
    ec.message.addError("Could not read ${sourceUrl}: ${e.message}")
}
