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
    ec.logger.info("AI Persona Generation requested for business: ${businessDescription}")
    
    // Step 1: Get owner party ID from authenticated user context
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
        .call()
    def ownerPartyId = ownerResult.ownerPartyId
    
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }
    
    ec.logger.info("Owner party ID: ${ownerPartyId}")
    
    // Step 2: Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    
    // Step 3: Construct prompt for persona generation
    def generationPrompt = """
Generate a detailed customer avatar (marketing persona) for the following business:

BUSINESS DESCRIPTION:
${businessDescription}

TARGET MARKET: ${targetMarket ?: 'Not specified - infer from business description'}

REQUIREMENTS:
1. Create a realistic customer avatar with a name (e.g., "Alex Johnson")
2. Demographics: Age range, occupation, income level, location type
3. Pain Points: 3-5 specific challenges this persona faces that the business solves
4. Goals: 3-5 aspirations or desired outcomes this persona wants to achieve
5. Tone of Voice: How this persona prefers to be communicated with (e.g., "Professional yet approachable", "Direct and data-driven")

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure.
ALL field values MUST be plain strings - never use JSON arrays or lists:
{
  "name": "Persona Name",
  "demographics": "Detailed demographics description as a single string",
  "painPoints": "Pain point 1. Pain point 2. Pain point 3. (all in one string, period-separated)",
  "goals": "Goal 1. Goal 2. Goal 3. (all in one string, period-separated)",
  "toneOfVoice": "Communication style description as a single string"
}

Generate the persona now.
"""

    ec.logger.info("Calling the configured LLM for persona generation...")
    
    // Step 4: Call the tenant's LLM (gemini, anthropic or openai)
    def jsonSlurper = new JsonSlurper()
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.7, maxOutputTokens: 2048])
    
    // Step 5: Extract generated content
    ec.logger.info("Generated persona text: ${generatedText}")
    
    // Clean up markdown code blocks if present
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').trim()
    
    // Step 6: Parse the JSON response
    def personaData = jsonSlurper.parseText(generatedText)

    // Normalize any fields that Gemini may return as arrays into newline-separated strings
    def normalizeField = { val ->
        if (val instanceof List) return val.join('\n')
        return val?.toString() ?: ''
    }
    personaData.painPoints  = normalizeField(personaData.painPoints)
    personaData.goals       = normalizeField(personaData.goals)
    personaData.demographics = normalizeField(personaData.demographics)
    personaData.toneOfVoice = normalizeField(personaData.toneOfVoice)

    // Step 7: Create the MarketingPersona entity
    def pseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
        .parameters([ownerPartyId: ownerPartyId, seqName: 'MarketingPersona'])
        .call()
    
    def createResult = ec.service.sync().name("create#growerp.marketing.MarketingPersona")
        .parameters([
            pseudoId: pseudoIdResult.seqNum,
            ownerPartyId: ownerPartyId,
            name: personaData.name,
            demographics: personaData.demographics,
            painPoints: personaData.painPoints,
            goals: personaData.goals,
            toneOfVoice: personaData.toneOfVoice,
            createdDate: ec.user.nowTimestamp,
            lastModifiedDate: ec.user.nowTimestamp
        ])
        .call()
    
    ec.logger.info("Created MarketingPersona with ID: ${createResult.personaId}")
    
    // Return the created persona
    personaId = createResult.personaId
    pseudoId = pseudoIdResult.seqNum
    name = personaData.name
    demographics = personaData.demographics
    painPoints = personaData.painPoints
    goals = personaData.goals
    toneOfVoice = personaData.toneOfVoice
    
    ec.message.addMessage("Marketing persona '${name}' generated successfully!")
    
} catch (Exception e) {
    ec.logger.error("Error generating persona with AI", e)
    ec.message.addError("Failed to generate persona: ${e.message}")
}
