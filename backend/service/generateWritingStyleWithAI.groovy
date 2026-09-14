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

import org.moqui.context.ExecutionContext

// Derive a reusable house-voice instruction block from samples of the tenant's own
// writing. Returns the text; it is NOT saved — the user reviews and edits it first.

ExecutionContext ec = context.ec ?: context

// guard rails: one analysis call, not a whole archive
final int MAX_SAMPLES = 20
final int MAX_CHARS_PER_SAMPLE = 6000

try {
    def ownerResult = ec.service.sync()
        .name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner").call()
    def ownerPartyId = ownerResult.ownerPartyId
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }

    def texts = (samples ?: []).collect { it?.toString()?.trim() }.findAll { it }
    if (!texts) {
        ec.message.addError("No sample text was supplied to analyse")
        return
    }
    if (texts.size() > MAX_SAMPLES) texts = texts.take(MAX_SAMPLES)
    texts = texts.collect { it.length() > MAX_CHARS_PER_SAMPLE ? it.take(MAX_CHARS_PER_SAMPLE) : it }

    def samplesBlock = texts.withIndex().collect { text, i ->
        "--- SAMPLE ${i + 1} ---\n${text}"
    }.join("\n\n")

    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

    def prompt = """
Below are samples of one author's own writing. Derive the author's VOICE and return it as a
reusable instruction block for whoever (or whatever) writes in that voice next.

Cover exactly these axes, one short bullet each, in this order:
- Title style
- Opening move (how a piece starts)
- Person and pronouns
- Register and tone
- Sentence rhythm and length
- Structure (how a piece is laid out)
- Closing ritual (any fixed sign-off, quoted exactly if there is one)
- What to avoid

Rules:
- Describe HOW the author writes, never WHAT these particular samples are about.
  The instructions must work for any future subject.
- Do not reproduce the author's spelling mistakes, typos or inconsistent capitalisation
  as if they were style. Voice, not mistakes.
- Around 250 words in total. Address the writer directly, in the imperative.
- Return ONLY the bullet list. No preamble, no headings, no markdown code fences.

${samplesBlock}
"""

    writingStyle = GeminiAiUtil.callLlmApi(ec, prompt,
        [ownerPartyId: ownerPartyId, temperature: 0.4, maxOutputTokens: 1024])
    writingStyle = writingStyle
        ?.replaceAll(/```\w*\s*/, '')?.replaceAll(/```\s*$/, '')?.trim()

    sampleCount = texts.size()
    ec.logger.info("Derived a writing style from ${texts.size()} samples for ${ownerPartyId}")

} catch (Exception e) {
    ec.logger.error("Error deriving writing style with AI", e)
    ec.message.addError("Failed to derive the writing style: ${e.message}")
}
