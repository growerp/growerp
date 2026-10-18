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

import groovy.json.JsonSlurper
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

    // A PLANNED piece of a content plan is written in place: its outline gives the input
    def planned = null
    if (masterContentId) {
        planned = ec.entity.find("growerp.marketing.MasterContent")
            .condition("masterContentId", masterContentId).condition("ownerPartyId", ownerPartyId).one()
        if (!planned) {
            ec.message.addError("Master content not found or access denied")
            return
        }
        if (planned.status != 'PLANNED') {
            ec.message.addError("Master content ${planned.pseudoId} is already written")
            return
        }
        planId = planned.planId
        contentType = planned.contentType ?: contentType
        pnpType = planned.pnpType ?: pnpType
        title = title ?: planned.title
        brief = brief ?: planned.brief
        targetUrl = targetUrl ?: planned.targetUrl
        if (!personaId && planId) personaId = ec.entity.find("growerp.marketing.ContentPlan")
            .condition("planId", planId).one()?.personaId
    }

    // Step 2: Persona (optional but recommended for tone)
    def persona = null
    if (personaId) {
        persona = ec.entity.find("growerp.marketing.MarketingPersona")
            .condition("personaId", personaId).condition("ownerPartyId", ownerPartyId).one()
    }

    def theType = (contentType ?: 'POSTING').toUpperCase()
    def thePnp = (pnpType ?: 'OTHER').toUpperCase()

    // Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

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
${title && brief ? "HEADLINE: ${title}\n" : ''}BRIEF / OUTLINE: ${brief ?: title ?: '(none, choose a strong angle for the persona)'}

HOUSE VOICE (how it must sound; wins over the persona tone where they disagree):
${GeminiAiUtil.houseVoice(ec, ownerPartyId)}

REQUIREMENTS:
- Speak directly to the persona in their tone of voice.
- Neutral formatting: no hashtags, no @mentions, no platform-specific styling (those are added on adaptation).
- The body is Markdown: short paragraphs of 1-3 sentences separated by a blank line${theType == 'ARTICLE' ? ", 2-4 '## ' subheadings" : ''},
  bullet lists and **bold** where they help. No '# ' heading (the title is separate), no tables, no HTML.
- Include a clear call-to-action.

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "title": "A short title/headline",
  "body": "The full platform-neutral content in Markdown",
  "callToAction": "One-line call to action"
}

Write the content now.
"""

    // Call the tenant's LLM (gemini, anthropic or openai)
    def jsonSlurper = new JsonSlurper()
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.85, maxOutputTokens: 4096])
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').replaceAll(/^```\s*/, '').trim()
    def data = jsonSlurper.parseText(generatedText)

    if (planned) {
        ec.service.sync().name("update#growerp.marketing.MasterContent")
            .parameters([masterContentId: masterContentId, contentType: theType, title: data.title,
                body: data.body, callToAction: data.callToAction ?: planned.callToAction,
                status: 'DRAFT', lastModifiedDate: ec.user.nowTimestamp]).call()
        ec.service.special().name("growerp.100.MasterContentServices100.generate#MasterContentImages")
            .parameters([masterContentIds: [masterContentId], username: ec.user.username]).registerOnCommit()
        pseudoId = planned.pseudoId
        title = data.title
        body = data.body
        callToAction = data.callToAction ?: planned.callToAction
        ec.message.addMessage("Planned piece ${pseudoId} written")
        return
    }

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
    // the related image is made in the background once this piece is committed
    ec.service.special().name("growerp.100.MasterContentServices100.generate#MasterContentImages")
        .parameters([masterContentIds: [masterContentId], username: ec.user.username]).registerOnCommit()
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
