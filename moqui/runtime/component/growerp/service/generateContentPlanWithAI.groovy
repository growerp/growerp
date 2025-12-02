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
    
    // Step 3: Get Gemini API key
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        apiKey = System.getenv("GEMINI_API_KEY")
    }
    if (apiKey == null || apiKey.isEmpty()) {
        ec.message.addError("Gemini API key not found. Please set GEMINI_API_KEY in user preferences or environment.")
        return
    }
    
    // Step 4: Determine week start date
    def weekStart = weekStartDate ? LocalDate.parse(weekStartDate as String) : LocalDate.now()
    def formatter = DateTimeFormatter.ISO_LOCAL_DATE
    
    // Step 5: Construct prompt for content plan generation
    def generationPrompt = """
Generate a weekly content plan using the Pain-News-Prize (PNP) formula for social media marketing.

CUSTOMER AVATAR:
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
Tone of Voice: ${persona.toneOfVoice}

WEEK STARTING: ${weekStart.format(formatter)}

CONTENT FORMULA (PNP):
- Monday: PAIN - Address a specific pain point or challenge the persona faces
- Wednesday: NEWS - Share industry news, trends, or insights relevant to the persona
- Friday: PRIZE - Offer value, solutions, or a call-to-action (e.g., free resource, consultation)

REQUIREMENTS:
1. Generate a theme for the week that ties all three posts together
2. For each day (Monday, Wednesday, Friday), create:
   - A compelling headline (10-15 words)
   - Post type (PAIN, NEWS, or PRIZE)
   - Brief content outline (2-3 sentences)
3. Ensure the content:
   - Speaks directly to the persona's pain points and goals
   - Uses the specified tone of voice
   - Includes a clear call-to-action for the PRIZE post
   - Is suitable for LinkedIn and other professional social media

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "theme": "Weekly theme description",
  "posts": [
    {
      "day": "Monday",
      "type": "PAIN",
      "headline": "Compelling headline addressing pain point",
      "outline": "Brief content outline"
    },
    {
      "day": "Wednesday",
      "type": "NEWS",
      "headline": "Headline about industry news or trend",
      "outline": "Brief content outline"
    },
    {
      "day": "Friday",
      "type": "PRIZE",
      "headline": "Headline offering value or solution",
      "outline": "Brief content outline with CTA"
    }
  ]
}

Generate the content plan now.
"""

    ec.logger.info("Calling Gemini API for content plan generation...")
    
    // Step 6: Call Gemini API
    def geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}"
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
            temperature: 0.8,
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
        ec.message.addError("Failed to generate content plan: ${errorText}")
        return
    }
    
    def responseText = connection.inputStream.text
    def jsonSlurper = new JsonSlurper()
    def geminiResponse = jsonSlurper.parseText(responseText)
    
    // Step 7: Extract generated content
    def generatedText = geminiResponse.candidates[0].content.parts[0].text
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
            theme: planData.theme,
            createdDate: ec.user.nowTimestamp,
            lastModifiedDate: ec.user.nowTimestamp
        ])
        .call()
    
    def planId = createPlanResult.planId
    ec.logger.info("Created ContentPlan with ID: ${planId}")
    
    // Step 10: Create SocialPost entities for each post in the plan
    def createdPosts = []
    planData.posts.each { post ->
        def postPseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
            .parameters([ownerPartyId: ownerPartyId, seqName: 'SocialPost'])
            .call()
        
        def createPostResult = ec.service.sync().name("create#growerp.marketing.SocialPost")
            .parameters([
                pseudoId: postPseudoIdResult.seqNum,
                ownerPartyId: ownerPartyId,
                planId: planId,
                type: post.type,
                headline: post.headline,
                draftContent: post.outline,
                status: 'DRAFT',
                createdDate: ec.user.nowTimestamp,
                lastModifiedDate: ec.user.nowTimestamp
            ])
            .call()
        
        createdPosts.add([
            postId: createPostResult.postId,
            type: post.type,
            headline: post.headline
        ])
        
        ec.logger.info("Created SocialPost (${post.type}) with ID: ${createPostResult.postId}")
    }
    
    // Return the created plan
    planId = planId
    pseudoId = pseudoIdResult.seqNum
    theme = planData.theme
    weekStartDate = weekStart.format(formatter)
    posts = createdPosts
    
    ec.message.addMessage("Content plan for week of ${weekStart.format(formatter)} generated successfully with ${createdPosts.size()} posts!")
    
} catch (Exception e) {
    ec.logger.error("Error generating content plan with AI", e)
    ec.message.addError("Failed to generate content plan: ${e.message}")
}
