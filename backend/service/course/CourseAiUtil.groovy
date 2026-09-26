/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import org.jsoup.Jsoup
import java.util.zip.ZipInputStream

/** Helpers for the course AI jobs: source text extraction and the LLM call. */
class CourseAiUtil {
    static final String USER_AGENT = "Mozilla/5.0 (compatible; GrowERP course builder)"
    static final int MAX_SOURCE_CHARS = 60000
    // every lesson prompt repeats the sources: keep them smaller there
    static final int MAX_LESSON_SOURCE_CHARS = 16000

    /** Plain text of an uploaded pdf, docx, markdown or text file; null for other types. */
    static String extractText(def ec, String fileName, byte[] bytes) {
        String name = (fileName ?: '').toLowerCase()
        if (name.endsWith('.pdf')) {
            def doc = org.apache.pdfbox.Loader.loadPDF(bytes)
            try {
                return new org.apache.pdfbox.text.PDFTextStripper().getText(doc)
            } finally {
                doc.close()
            }
        }
        if (name.endsWith('.docx')) {
            // a docx is a zip; the text is in word/document.xml, one w:p per paragraph
            def zip = new ZipInputStream(new ByteArrayInputStream(bytes))
            def entry
            while ((entry = zip.nextEntry) != null) {
                if (entry.name == 'word/document.xml') {
                    String xml = new String(zip.readAllBytes(), 'UTF-8')
                    return xml.replaceAll(/<\/w:p>/, '\n').replaceAll(/<[^>]+>/, '')
                        .replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
                        .replace('&quot;', '"').replace('&apos;', "'")
                }
            }
            return null
        }
        if (name.endsWith('.md') || name.endsWith('.txt') || name.endsWith('.markdown')) {
            return new String(bytes, 'UTF-8')
        }
        ec.message.addError("File type of ${fileName} not supported, use pdf, docx, md or txt")
        return null
    }

    /** Readable text of a web page. */
    static String fetchUrlText(String url) {
        def doc = Jsoup.connect(url).userAgent(USER_AGENT).timeout(20000)
            .maxBodySize(5 * 1024 * 1024).followRedirects(true).get()
        doc.select('script, style, nav, footer, header, noscript').remove()
        String title = doc.title()
        return (title ? "# ${title}\n\n" : '') + doc.body()?.text()
    }

    /** GeminiAiUtil errors the tenant fixes by entering (or raising the cap of) its own API key. */
    static boolean isAllowanceError(Throwable t) {
        String message = t?.message ?: ''
        return message.contains('AI allowance used') || message.contains('AI token limit reached') ||
            message.contains('No API key configured')
    }

    static boolean testMode() {
        return 'true'.equals(System.getenv('GROWERP_TEST_MODE'))
    }

    /**
     * Ask the LLM for a JSON answer and parse it. In test mode (CI) no AI is called: the
     * canned answer is returned instead so the tests are deterministic and free.
     */
    static def askJson(def ec, String ownerPartyId, String prompt, def testAnswer) {
        if (testMode()) return testAnswer
        def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
        // long markdown inside json now and then comes back badly escaped: ask once more
        for (int attempt = 1; ; attempt++) {
            String text = GeminiAiUtil.callLlmApi(ec, prompt,
                [ownerPartyId: ownerPartyId, jsonMode: true, maxOutputTokens: 16384])
            try {
                return GeminiAiUtil.parseJsonResponse(text)
            } catch (groovy.json.JsonException e) {
                if (attempt >= 2) throw new Exception("The AI returned invalid JSON: ${e.message?.take(200)}")
                ec.logger.warn("Course AI returned invalid JSON, retrying: ${e.message?.take(200)}")
            }
        }
    }
}

// Return the utility class for use by other scripts
return CourseAiUtil
