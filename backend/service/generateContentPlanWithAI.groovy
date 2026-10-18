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
import java.time.LocalDate
import java.time.format.DateTimeFormatter

// Get ExecutionContext
ExecutionContext ec = context.ec ?: context

try {
    ec.logger.info("AI Content Plan Generation requested for persona: ${personaId}")
    
    // Step 1: Get owner party ID
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
        .call()
    def ownerPartyId = ownerResult.ownerPartyId
    
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }
    
    // Step 2: Fetch the persona details
    def persona = ec.entity.find("growerp.marketing.MarketingPersona")
        .condition("personaId", personaId)
        .condition("ownerPartyId", ownerPartyId)
        .one()
    
    if (!persona) {
        ec.message.addError("Persona not found or access denied")
        return
    }
    
    ec.logger.info("Generating content plan for persona: ${persona.name}")
    
    // Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    
    // Step 4: Determine the plan's first week (its Monday) and its shape
    // Flutter sends weekStartDate as epoch milliseconds (Long); fall back to today
    LocalDate weekStart
    if (weekStartDate) {
        weekStart = new java.util.Date(weekStartDate as long)
            .toInstant()
            .atZone(java.time.ZoneId.of("UTC"))
            .toLocalDate()
    } else {
        weekStart = LocalDate.now()
    }
    weekStart = weekStart.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
    int planWeeks = Math.max(1, Math.min((weeks ?: 4) as int, 12))
    def format = planFormat == 'SINGLE' ? 'SINGLE' : 'PNP'
    // the slots of one week: angle and day offset from Monday
    def slots = format == 'SINGLE' ? [[type: 'OTHER', day: 0]]
        : [[type: 'PAIN', day: 0], [type: 'NEWS', day: 2], [type: 'PRIZE', day: 4]]

    def formatter = DateTimeFormatter.ISO_LOCAL_DATE

    // Optional user direction; captured before 'theme' is overwritten with the AI result
    def userDirection = theme?.toString()?.trim()
    def directionSection = userDirection ? """USER DIRECTION (theme & strategy for the plan):
${userDirection}
Build the plan theme and every week around this direction.

""" : ""

    def formulaSection = format == 'SINGLE' ? """CONTENT FORMAT: ONE posting per week, published on Monday. Each week picks the most
useful angle for the persona that week (a pain, a trend or a concrete offer); use type "OTHER".""" :
"""CONTENT FORMULA (Pain-News-Prize), three pieces per week:
- Monday: PAIN - Address a specific pain point or challenge the persona faces
- Wednesday: NEWS - Share industry news, trends, or insights relevant to the persona
- Friday: PRIZE - Offer value, solutions, or a call-to-action (e.g., free resource, consultation)"""
    def itemsExample = slots.collect { slot -> """        {
          "type": "${slot.type}",
          "headline": "Compelling headline",
          "brief": "2-3 sentences: the point to make, the key facts or examples, the angle",
          "callToAction": "One-line call to action"
        }""" }.join(',\n')

    // Step 5: Construct prompt for the plan outline; the bodies are written week by week
    def generationPrompt = """
Generate a ${planWeeks}-week content plan OUTLINE for social media marketing.
Do NOT write the posts themselves: each piece is written in its own week from your brief.

CUSTOMER AVATAR:
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
Tone of Voice: ${persona.toneOfVoice}

FIRST WEEK STARTING: ${weekStart.format(formatter)}

${directionSection}${formulaSection}

REQUIREMENTS:
1. A one-sentence theme for the whole plan${userDirection ? ' that captures the user direction' : ''}.
2. For each of the ${planWeeks} weeks: a one-sentence week theme, building on the previous
   weeks without repeating a topic, and ${slots.size() == 1 ? 'one piece' : 'three pieces in the order above'} with:
   - A compelling headline (10-15 words)
   - A brief of 2-3 sentences: the point, the facts or examples to use, the angle
   - A one-line call to action
3. Speak to the persona's pain points and goals, in the specified tone of voice.
4. Platform-neutral: no hashtags, no platform-specific formatting.

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure,
with exactly ${planWeeks} entries in "weeks":
{
  "theme": "Plan theme",
  "weeks": [
    {
      "theme": "Week theme",
      "pieces": [
${itemsExample}
      ]
    }
  ]
}

Generate the content plan outline now.
"""

    ec.logger.info("Calling the configured LLM API for content plan generation...")
    
    // Call the tenant's LLM (gemini, anthropic or openai)
    def jsonSlurper = new JsonSlurper()
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.8, maxOutputTokens: 8192])
    ec.logger.info("Generated content plan text: ${generatedText}")
    
    // Clean up markdown code blocks if present
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').trim()
    
    // Step 8: Parse the JSON response
    def planData = jsonSlurper.parseText(generatedText)
    
    // Step 9: Create the ContentPlan entity
    def pseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
        .parameters([ownerPartyId: ownerPartyId, seqName: 'ContentPlan'])
        .call()
    
    def createPlanResult = ec.service.sync().name("create#growerp.marketing.ContentPlan")
        .parameters([
            pseudoId: pseudoIdResult.seqNum,
            ownerPartyId: ownerPartyId,
            personaId: personaId,
            weekStartDate: java.sql.Date.valueOf(weekStart),
            weeks: planWeeks,
            planFormat: format,
            theme: planData.theme,
            createdDate: ec.user.nowTimestamp,
            lastModifiedDate: ec.user.nowTimestamp
        ])
        .call()
    
    planId = createPlanResult.planId
    ec.logger.info("Created ContentPlan with ID: ${planId}")
    
    // Step 10: Create a PLANNED MasterContent piece per slot: title, brief and date only.
    // The body is written in its week (generate#MasterContent with the masterContentId),
    // social posts later by adapt#ContentForPlatform (author once -> fan out)
    def createdContents = []
    (planData.weeks ?: []).take(planWeeks).eachWithIndex { week, weekIndex ->
        (week.pieces ?: []).take(slots.size()).eachWithIndex { piece, slotIndex ->
            def slot = slots[slotIndex]
            // 10:00 UTC, the hour adapt#ContentForPlatform also uses
            def plannedDate = java.sql.Timestamp.from(weekStart.plusWeeks(weekIndex)
                .plusDays(slot.day).atTime(10, 0).toInstant(java.time.ZoneOffset.UTC))
            def contentPseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                .parameters([ownerPartyId: ownerPartyId, seqName: 'MasterContent'])
                .call()

            def createContentResult = ec.service.sync().name("create#growerp.marketing.MasterContent")
                .parameters([
                    pseudoId: contentPseudoIdResult.seqNum,
                    ownerPartyId: ownerPartyId,
                    planId: planId,
                    contentType: 'POSTING',
                    pnpType: slot.type,
                    title: piece.headline,
                    brief: (week.theme ? "Week theme: ${week.theme}\n\n" : '') + (piece.brief ?: ''),
                    callToAction: piece.callToAction,
                    plannedDate: plannedDate,
                    status: 'PLANNED',
                    createdDate: ec.user.nowTimestamp,
                    lastModifiedDate: ec.user.nowTimestamp
                ])
                .call()

            createdContents.add([
                masterContentId: createContentResult.masterContentId,
                pnpType: slot.type,
                title: piece.headline,
                plannedDate: plannedDate
            ])
        }
    }
    ec.logger.info("Created ${createdContents.size()} PLANNED MasterContent pieces for plan ${planId}")

    // Return the created plan with the same field shapes as list#ContentPlans
    // (dates as epoch millis, personaId included) so the frontend can insert
    // the response straight into its list without a refetch
    pseudoId = pseudoIdResult.seqNum
    theme = planData.theme
    weekStartDate = java.sql.Date.valueOf(weekStart)
    weeks = planWeeks
    planFormat = format
    createdDate = ec.user.nowTimestamp
    lastModifiedDate = ec.user.nowTimestamp
    masterContents = createdContents

    ec.message.addMessage("Content plan of ${planWeeks} weeks from ${weekStart.format(formatter)} generated with ${createdContents.size()} planned pieces")
    
} catch (Exception e) {
    ec.logger.error("Error generating content plan with AI", e)
    ec.message.addError("Failed to generate content plan: ${e.message}")
}
