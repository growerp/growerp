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
 * Pure text helpers for translateWebsiteWithAI.groovy, a class so the Spock spec can test them
 * without a Gemini call.
 */
class WebsiteTranslationUtil {
    static final String TITLE_COMMENT = /<#--\s*title:.*?-->/
    // the title comment plus the line break after it, so taking it out leaves no blank line
    static final String TITLE_LINE = /<#--\s*title:.*?-->[ \t]*\r?\n?/

    /**
     * An .html.ftl page has to start with its '<#-- title: X -->' line (the navbar and the
     * Website dialog read it there), but the model does not always keep it first: it moves the
     * description comment up, puts a BOM or a sentence in front, or drops the title. Put the
     * translated title back on line 1, or the untranslated source title when the model dropped it.
     * A source page without a title line is left as the model returned it.
     */
    static String normalizeFtlTitle(String source, String translated) {
        String text = (translated ?: '').replace('\uFEFF', '').trim()
        def titleMatch = text =~ TITLE_LINE
        String title
        if (titleMatch.find()) {
            title = titleMatch.group().trim()
            text = (text.substring(0, titleMatch.start()) + text.substring(titleMatch.end())).trim()
        } else {
            def sourceMatch = (source ?: '').replace('\uFEFF', '') =~ TITLE_COMMENT
            if (!sourceMatch.find()) return text
            title = sourceMatch.group()
        }
        // anything in front of the first tag is model chatter, not page content
        int firstTag = text.indexOf('<')
        if (firstTag > 0) text = text.substring(firstTag)
        return title + '\n' + text
    }
}

return WebsiteTranslationUtil
