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
 * Translate one website page into one locale, keeping the file a valid GrowERP website page
 * (see docs/Website_Template_Definition.md).
 *
 * One call per page: a whole-site call would run past maxOutputTokens and truncate, the same
 * reason generateWebsiteWithAI.groovy splits its page bodies.
 *
 * The internal links are rewritten here rather than by the model: a regex over the finished
 * text is exact, while a model asked to edit href values also 'improves' the ones it should
 * have left alone.
 *
 * In:  pageText, contentType ('md' or 'ftl'), sourceLocale, targetLocale, apiKey, ownerPartyId
 * Out: translatedText
 */

import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

final Map LANGUAGE_NAMES = [en: 'English', th: 'Thai', zh: 'Simplified Chinese',
                            de: 'German', fr: 'French', nl: 'Dutch']

def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

/** models like to wrap their answer in a ``` fence even when told not to */
def stripFences = { String text ->
    String t = (text ?: '').trim()
    t = t.replaceAll(/(?s)^```[a-zA-Z]*\s*/, '').replaceAll(/(?s)\s*```$/, '')
    return t.trim()
}

/**
 * Point the site internal links at the translated tree: /content/x -> /th/content/x and the
 * home link / -> /th/. Anything with a scheme, a leading '#' or an already prefixed path is
 * left alone.
 */
def localizeLinks = { String text, String locale ->
    String t = text ?: ''
    // href="/content/x" and href='/content/x', also src= for the same tree
    t = t.replaceAll(/((?:href|src)=["'])\/content\//, "\$1/${locale}/content/")
    // markdown [label](/content/x)
    t = t.replaceAll(/(\]\()\/content\//, "\$1/${locale}/content/")
    // the bare home link
    t = t.replaceAll(/((?:href)=["'])\/(["'])/, "\$1/${locale}/\$2")
    t = t.replaceAll(/(\]\()\/(\))/, "\$1/${locale}/\$2")
    return t
}

String sourceName = LANGUAGE_NAMES[sourceLocale as String] ?: (sourceLocale as String)
String targetName = LANGUAGE_NAMES[targetLocale as String] ?: (targetLocale as String)
boolean isMd = contentType == 'md'

String structureRules = isMd ? """
- This is a Markdown file rendered inside the site template.
- Keep every heading at the level it has now: the page sidebar is built from the '# ' and
  '## ' headings, so adding, removing or re-levelling one breaks the anchors.
- Keep list markers, tables, code blocks and any inline HTML exactly as they are.
""" : """
- This is a FreeMarker/HTML page.
- The first line is a FreeMarker comment '<#-- title: Some Title -->'. Keep that exact form
  and translate only the title text inside it.
- Keep the HTML structure byte for byte: same tags, same nesting, same order.
- Do not touch any attribute value. That includes every class="...", id="...", style="...",
  and the data-growerp-form, data-growerp-plans and data-growerp-booking markers, which the
  server replaces with live content at render time.
"""

String prompt = """
Translate the ${sourceName} website page below into ${targetName}.

You are translating a live company website, so the result has to read as if it was written in
${targetName} by the company itself: natural, idiomatic marketing copy, not a literal
word-for-word rendering. Keep the tone and the length of the original.

TRANSLATE
- All human visible text: headings, paragraphs, list items, button and link labels, table
  cells, image alt text, and the text of any title="..." or aria-label="..." attribute.
- The SEO description in an HTML comment of the form '<!-- description: ... -->', keeping the
  comment itself in that exact form.

DO NOT TRANSLATE OR CHANGE
- Company names, product names, brand names and people's names.
- Email addresses, phone numbers, postal addresses, URLs and href/src values.
- Anything between \${ and }, and any other FreeMarker directive.
${structureRules}
OUTPUT
Return the complete translated file and nothing else: no explanation, no commentary, no ```
fence around it. The first character of your answer is the first character of the file.

PAGE:
${pageText}
"""

Map aiOptions = [apiKey: apiKey, ownerPartyId: ownerPartyId, jsonMode: false,
                 temperature: 0.2, maxOutputTokens: 8192]

String raw = GeminiAiUtil.callGeminiApi(ec, prompt, aiOptions)
String text = stripFences(raw)

if (!text) throw new Exception("The AI returned no text for the ${targetName} translation")
// a truncated answer is worse than none: it would be published as the translated page
if (text.length() < ((pageText as String).length() / 3)) {
    throw new Exception("The ${targetName} translation came back far shorter than the source page," +
        " it was probably truncated")
}
if (!isMd && !text.startsWith('<#--')) {
    throw new Exception("The ${targetName} translation does not start with the required" +
        " '<#-- title: ... -->' line")
}

translatedText = localizeLinks(text, targetLocale as String)
