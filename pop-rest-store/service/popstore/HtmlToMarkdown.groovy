/*
This software is in the public domain under CC0 1.0 Universal plus a
Grant of Patent License.

To the extent possible under law, the author(s) have dedicated all
copyright and related and neighboring rights to this software to the
public domain worldwide. This software is distributed without any
warranty.

You should have received a copy of the CC0 Public Domain Dedication
along with this software (see the LICENSE.md file). If not, see
<http://creativecommons.org/publicdomain/zero/1.0/>.
*/

import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.nodes.Node
import org.jsoup.nodes.TextNode

/**
 * Converts a store content page (an html fragment, see generateWebsiteWithAI.groovy for the
 * tag set it may contain) to markdown for AI/LLM consumers. Used by SeoServices get#PageMarkdown.
 *
 * Usage:
 *   def h2m = ec.resource.script("component://PopRestStore/service/popstore/HtmlToMarkdown.groovy", null)
 *   String markdown = h2m.convert(html, baseUrl)
 */
class HtmlToMarkdown {

    /** tags carrying no prose: chrome, scripts, interactive widgets, material symbol ligatures */
    static final String DROP_SELECTOR = "script,style,svg,noscript,iframe,form,button,input,select," +
            "textarea,nav,header,footer,span.material-symbols-outlined,[aria-hidden=true]," +
            "[data-growerp-form],[data-growerp-plans]"

    static String convert(String html, String baseUrl) {
        Document doc = Jsoup.parseBodyFragment(html ?: '')
        doc.outputSettings().prettyPrint(false)
        doc.select(DROP_SELECTOR).remove()
        Element root = doc.selectFirst('main') ?: doc.body()
        StringBuilder out = new StringBuilder()
        for (Element child in root.children()) block(child, out, 0, baseUrl ?: '')
        return out.toString().replaceAll(/[ \t]+\n/, '\n').replaceAll(/\n{3,}/, '\n\n').trim() + '\n'
    }

    /** markdown text within a paragraph, heading or table cell */
    static String inline(Node node, String baseUrl) {
        StringBuilder b = new StringBuilder()
        for (Node child in node.childNodes()) {
            if (child instanceof TextNode) { b.append(escape(((TextNode) child).text())); continue }
            if (!(child instanceof Element)) continue
            Element e = (Element) child
            String tag = e.tagName()
            if (tag == 'br') { b.append('  \n') }
            else if (tag == 'strong' || tag == 'b') { b.append(wrap(inline(e, baseUrl), '**')) }
            else if (tag == 'em' || tag == 'i') { b.append(wrap(inline(e, baseUrl), '*')) }
            else if (tag == 'code') { b.append('`').append(e.text()).append('`') }
            else if (tag == 'a') {
                String text = inline(e, baseUrl).trim()
                if (text) b.append('[').append(text).append('](').append(absolute(e.attr('href'), baseUrl)).append(')')
            } else if (tag == 'img') {
                b.append('![').append(escape(e.attr('alt'))).append('](').append(absolute(e.attr('src'), baseUrl)).append(')')
            } else if (tag == 'span' && e.hasClass('material-symbols-outlined')) {
                // material symbols ligature: an icon name, not prose
            } else {
                b.append(inline(e, baseUrl))
            }
        }
        return b.toString()
    }

    /** block level markdown; depth is the list nesting level */
    static void block(Element e, StringBuilder out, int depth, String baseUrl) {
        String tag = e.tagName()
        if (tag ==~ /h[1-6]/) {
            String text = inline(e, baseUrl).trim()
            if (text) out.append('\n').append('#' * (tag.substring(1) as int)).append(' ').append(text).append('\n\n')
        } else if (tag == 'p') {
            String text = inline(e, baseUrl).trim()
            if (text) out.append(text).append('\n\n')
        } else if (tag == 'ul' || tag == 'ol') {
            boolean ordered = tag == 'ol'
            int index = 0
            for (Element li in e.children().findAll({ it.tagName() == 'li' })) {
                index++
                Element shallow = li.clone()
                shallow.select('ul,ol').remove()
                String text = inline(shallow, baseUrl).trim()
                if (text) out.append('  ' * depth).append(ordered ? "${index}. " : '- ').append(text).append('\n')
                for (Element sub in li.select('> ul, > ol')) block(sub, out, depth + 1, baseUrl)
            }
            out.append('\n')
        } else if (tag == 'blockquote') {
            StringBuilder inner = new StringBuilder()
            for (Element child in e.children()) block(child, inner, 0, baseUrl)
            inner.toString().trim().eachLine({ out.append('> ').append(it).append('\n') })
            out.append('\n')
        } else if (tag == 'pre') {
            out.append('```\n').append(e.text()).append('\n```\n\n')
        } else if (tag == 'hr') {
            out.append('---\n\n')
        } else if (tag == 'table') {
            List<Element> rows = e.select('tr')
            rows.eachWithIndex({ Element row, int rowIndex ->
                List<Element> cells = row.select('th,td')
                out.append('| ').append(cells.collect({ inline(it, baseUrl).trim() }).join(' | ')).append(' |\n')
                if (rowIndex == 0) out.append('|').append(' --- |' * cells.size()).append('\n')
            })
            out.append('\n')
        } else if (tag == 'img') {
            out.append('![').append(escape(e.attr('alt'))).append('](').append(absolute(e.attr('src'), baseUrl)).append(')\n\n')
        } else if (e.children().isEmpty()) {
            // layout container without element children: a text leaf
            String text = inline(e, baseUrl).trim()
            if (text) out.append(text).append('\n\n')
        } else {
            // main/section/div/article/figure/...: keep walking
            for (Element child in e.children()) block(child, out, depth, baseUrl)
        }
    }

    static String wrap(String text, String marker) {
        String trimmed = text.trim()
        return trimmed ? marker + trimmed + marker : ''
    }

    static String escape(String text) { return text == null ? '' : text.replaceAll(/([\\\[\]*_`|])/, '\\\\$1') }

    static String absolute(String url, String baseUrl) {
        if (!url) return ''
        if (url.startsWith('http') || url.startsWith('mailto:') || url.startsWith('tel:') || url.startsWith('#')) return url
        return url.startsWith('/') ? baseUrl + url : url
    }
}

// return the utility class for use by the SeoServices services
return HtmlToMarkdown
