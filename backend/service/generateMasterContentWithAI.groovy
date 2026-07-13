/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import org.moqui.context.ExecutionContext

// Get ExecutionContext
ExecutionContext ec = context.ec ?: context

try {
    ec.logger.info("AI Master Content generation requested (persona: ${personaId}, type: ${contentType}, pnp: ${pnpType})")

    // Step 1: Owner
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner").call()
    def ownerPartyId = ownerResult.ownerPartyId
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }

    // Step 2: Persona (optional but recommended for tone)
    def persona = null
    if (personaId) {
        persona = ec.entity.find("growerp.marketing.MarketingPersona")
            .condition("personaId", personaId).condition("ownerPartyId", ownerPartyId).one()
    }

    def theType = (contentType ?: 'POSTING').toUpperCase()
    def thePnp = (pnpType ?: 'OTHER').toUpperCase()

    // Step 3: API key
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) apiKey = System.getenv("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        ec.message.addError("Gemini API key not found. Please set GEMINI_API_KEY in user preferences or environment.")
        return
    }

    // Step 4: Prompt — produce ONE platform-neutral canonical piece
    def personaBlock = persona ? """
CUSTOMER AVATAR:
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
Tone of Voice: ${persona.toneOfVoice}
""" : "CUSTOMER AVATAR: SMB owner running the business on spreadsheets."

    def typeGuide = theType == 'ARTICLE' ? "a long-form article (500-900 words) with a clear structure" :
                    theType == 'MESSAGE' ? "a short, personal 1:1 outreach message (60-120 words)" :
                    "a concise social posting (120-250 words)"

    def pnpGuide = thePnp == 'PAIN' ? "identify with a specific pain point and show empathy" :
                   thePnp == 'NEWS' ? "share a valuable insight, trend or announcement" :
                   thePnp == 'PRIZE' ? "offer clear value and a call-to-action" :
                   "inform and engage the reader"

    def generationPrompt = """
Write ONE platform-neutral marketing piece. Do NOT tailor it to any single platform — it will be
adapted per platform later. Write ${typeGuide}.

${personaBlock}

ANGLE (Pain-News-Prize): ${thePnp} — ${pnpGuide}
BRIEF / OUTLINE: ${brief ?: title ?: '(none, choose a strong angle for the persona)'}

REQUIREMENTS:
- Speak directly to the persona in their tone of voice.
- Neutral formatting: no hashtags, no @mentions, no platform-specific styling (those are added on adaptation).
- Include a clear call-to-action.

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "title": "A short title/headline",
  "body": "The full platform-neutral content",
  "callToAction": "One-line call to action"
}

Write the content now.
"""

    // Step 5: Call Gemini
    def tenantModel = ec.entity.find("growerp.general.SystemSettings").condition("ownerPartyId", ownerPartyId).one()?.aiModelName
    def model = tenantModel ?: ec.user.getPreference("GEMINI_MODEL") ?: System.getenv("GEMINI_MODEL") ?: System.getProperty("GEMINI_MODEL") ?: "gemini-2.5-flash-lite"
    def geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}"
    def connection = new URL(geminiUrl).openConnection() as HttpURLConnection
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setDoOutput(true)

    def requestBody = JsonOutput.toJson([
        contents: [[ parts: [[text: generationPrompt]] ]],
        generationConfig: [temperature: 0.85, topK: 40, topP: 0.95, maxOutputTokens: 4096]
    ])
    connection.outputStream.withWriter("UTF-8") { writer -> writer.write(requestBody) }

    def responseCode = connection.responseCode
    ec.logger.info("Gemini API response code: ${responseCode}")
    if (responseCode != 200) {
        def errorStream = connection.errorStream
        def errorText = errorStream ? errorStream.text : "No error details available"
        ec.logger.error("Gemini API error: ${errorText}")
        ec.message.addError("Failed to generate master content: ${errorText}")
        return
    }

    def jsonSlurper = new JsonSlurper()
    def geminiResponse = jsonSlurper.parseText(connection.inputStream.text)
    def generatedText = geminiResponse.candidates[0].content.parts[0].text
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').replaceAll(/^```\s*/, '').trim()
    def data = jsonSlurper.parseText(generatedText)

    // Step 6: Create the MasterContent entity
    def pseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
        .parameters([ownerPartyId: ownerPartyId, seqName: 'MasterContent']).call()

    def createResult = ec.service.sync().name("create#growerp.marketing.MasterContent")
        .parameters([
            pseudoId: pseudoIdResult.seqNum,
            ownerPartyId: ownerPartyId,
            planId: planId,
            contentType: theType,
            pnpType: thePnp,
            title: data.title,
            body: data.body,
            callToAction: data.callToAction,
            targetUrl: targetUrl,
            status: 'DRAFT',
            createdDate: ec.user.nowTimestamp,
            lastModifiedDate: ec.user.nowTimestamp
        ]).call()

    masterContentId = createResult.masterContentId
    pseudoId = pseudoIdResult.seqNum
    title = data.title
    body = data.body
    callToAction = data.callToAction

    ec.logger.info("Created MasterContent ${masterContentId}")
    ec.message.addMessage("Master content generated successfully!")

} catch (Exception e) {
    ec.logger.error("Error generating master content with AI", e)
    ec.message.addError("Failed to generate master content: ${e.message}")
}
