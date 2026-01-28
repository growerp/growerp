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
    
    // Step 2: Get Gemini API key
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        apiKey = System.getenv("GEMINI_API_KEY")
    }
    if (apiKey == null || apiKey.isEmpty()) {
        ec.message.addError("Gemini API key not found. Please set GEMINI_API_KEY in user preferences or environment.")
        return
    }
    
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

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "name": "Persona Name",
  "demographics": "Detailed demographics description",
  "painPoints": "Bullet-pointed list of pain points",
  "goals": "Bullet-pointed list of goals and aspirations",
  "toneOfVoice": "Communication style description"
}

Generate the persona now.
"""

    ec.logger.info("Calling Gemini API for persona generation...")
    
    // Step 4: Call Gemini API
    def geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}"
    def connection = new URL(geminiUrl).openConnection() as HttpURLConnection
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setDoOutput(true)
    
    def requestBody = JsonOutput.toJson([
        contents: [
            [
                parts: [
                    [text: generationPrompt]
                ]
            ]
        ],
        generationConfig: [
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048
        ]
    ])
    
    connection.outputStream.withWriter("UTF-8") { writer ->
        writer.write(requestBody)
    }
    
    def responseCode = connection.responseCode
    ec.logger.info("Gemini API response code: ${responseCode}")
    
    if (responseCode != 200) {
        def errorStream = connection.errorStream
        def errorText = errorStream ? errorStream.text : "No error details available"
        ec.logger.error("Gemini API error: ${errorText}")
        ec.message.addError("Failed to generate persona: ${errorText}")
        return
    }
    
    def responseText = connection.inputStream.text
    def jsonSlurper = new JsonSlurper()
    def geminiResponse = jsonSlurper.parseText(responseText)
    
    // Step 5: Extract generated content
    def generatedText = geminiResponse.candidates[0].content.parts[0].text
    ec.logger.info("Generated persona text: ${generatedText}")
    
    // Clean up markdown code blocks if present
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').trim()
    
    // Step 6: Parse the JSON response
    def personaData = jsonSlurper.parseText(generatedText)
    
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
