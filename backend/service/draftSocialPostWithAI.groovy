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
    
    // Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    
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

    ec.logger.info("Calling the configured LLM API for post drafting...")
    
    // Call the tenant's LLM (gemini, anthropic or openai)
    def jsonSlurper = new JsonSlurper()
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.9, maxOutputTokens: 1024])
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
