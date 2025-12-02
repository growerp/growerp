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
    ec.logger.info("AI Social Post Drafting requested for post: ${postId}")
    
    // Step 1: Get owner party ID
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
        .call()
    def ownerPartyId = ownerResult.ownerPartyId
    
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }
    
    // Step 2: Fetch the social post details
    def post = ec.entity.find("growerp.marketing.SocialPost")
        .condition("postId", postId)
        .condition("ownerPartyId", ownerPartyId)
        .one()
    
    if (!post) {
        ec.message.addError("Social post not found or access denied")
        return
    }
    
    // Step 3: Fetch the content plan
    def plan = ec.entity.find("growerp.marketing.ContentPlan")
        .condition("planId", post.planId)
        .one()
    
    if (!plan) {
        ec.message.addError("Content plan not found")
        return
    }
    
    // Step 4: Fetch the persona
    def persona = ec.entity.find("growerp.marketing.MarketingPersona")
        .condition("personaId", plan.personaId)
        .one()
    
    if (!persona) {
        ec.message.addError("Persona not found")
        return
    }
    
    ec.logger.info("Drafting ${post.type} post for persona: ${persona.name}")
    
    // Step 5: Get Gemini API key
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        apiKey = System.getenv("GEMINI_API_KEY")
    }
    if (apiKey == null || apiKey.isEmpty()) {
        ec.message.addError("Gemini API key not found. Please set GEMINI_API_KEY in user preferences or environment.")
        return
    }
    
    // Step 6: Construct prompt for post drafting
    def generationPrompt = """
Draft a complete, ready-to-publish social media post for LinkedIn and other professional platforms.

CUSTOMER AVATAR:
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
Tone of Voice: ${persona.toneOfVoice}

POST DETAILS:
Type: ${post.type}
Headline: ${post.headline}
Outline: ${post.draftContent}
Weekly Theme: ${plan.theme}

REQUIREMENTS:
1. Write a complete post (200-300 words) that:
   - Opens with a hook that grabs attention
   - Addresses the headline topic in depth
   - Speaks directly to the persona using their tone of voice
   - ${post.type == 'PAIN' ? 'Identifies with the pain point and shows empathy' : ''}
   - ${post.type == 'NEWS' ? 'Provides valuable insights or industry perspective' : ''}
   - ${post.type == 'PRIZE' ? 'Offers clear value and includes a strong call-to-action' : ''}
   - Ends with a "Signal of Interest Elicitor" question (e.g., "What do you think?", "Have you experienced this?")

2. Format the post for social media:
   - Use short paragraphs (1-2 sentences)
   - Include 1-2 relevant emojis (sparingly)
   - Add 3-5 relevant hashtags at the end

3. Make it "humanized" - avoid overly corporate or AI-sounding language

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "content": "The complete post text with formatting",
  "hashtags": ["hashtag1", "hashtag2", "hashtag3"]
}

Draft the post now.
"""

    ec.logger.info("Calling Gemini API for post drafting...")
    
    // Step 7: Call Gemini API
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
            temperature: 0.9,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024
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
        ec.message.addError("Failed to draft post: ${errorText}")
        return
    }
    
    def responseText = connection.inputStream.text
    def jsonSlurper = new JsonSlurper()
    def geminiResponse = jsonSlurper.parseText(responseText)
    
    // Step 8: Extract generated content
    def generatedText = geminiResponse.candidates[0].content.parts[0].text
    ec.logger.info("Generated post text: ${generatedText}")
    
    // Clean up markdown code blocks if present
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').trim()
    
    // Step 9: Parse the JSON response
    def postData = jsonSlurper.parseText(generatedText)
    
    // Step 10: Update the SocialPost with the drafted content
    def hashtagsString = postData.hashtags.collect { "#${it}" }.join(' ')
    def fullContent = "${postData.content}\n\n${hashtagsString}"
    
    ec.service.sync().name("update#growerp.marketing.SocialPost")
        .parameters([
            postId: postId,
            draftContent: fullContent,
            lastModifiedDate: ec.user.nowTimestamp
        ])
        .call()
    
    ec.logger.info("Updated SocialPost ${postId} with drafted content")
    
    // Return the drafted content
    content = fullContent
    hashtags = postData.hashtags
    
    ec.message.addMessage("Social post drafted successfully!")
    
} catch (Exception e) {
    ec.logger.error("Error drafting post with AI", e)
    ec.message.addError("Failed to draft post: ${e.message}")
}
