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
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

// Get ExecutionContext
ExecutionContext ec = context.ec ?: context

try {
    def user = ec.user
    
    ec.logger.info("AI Landing Page Generation requested for business: ${businessDescription}")
    
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
        ec.message.addError("Gemini API key not found")
        return
    }
    
    // Step 3: Construct comprehensive prompt for ALL landing page components in single call
    def generationPrompt = """
Generate a COMPLETE, production-ready landing page in a single comprehensive response.

BUSINESS DESCRIPTION:
${businessDescription}

TARGET AUDIENCE: ${targetAudience ?: 'Not specified - infer from business description'}

INDUSTRY: ${industry ?: 'Infer from business description'}

TONE: ${tone}

REQUIREMENTS:
1. Compelling Results Hook (headline) - focus on tangible outcomes
2. Clear subheading with action guidance
3. Generate ${numSections} distinct page sections (each with title, description, and unique value)
4. Hero section with compelling narrative
5. Features/Benefits section highlighting 3 core value propositions
6. Credibility/Trust section with:
   - Company/Author background story
   - Industry-specific statistics (minimum 4 stats with realistic numbers)
   - Social proof elements
7. Call-to-action section with primary and secondary actions
8. FAQ or Objection-handling section if applicable

CONSTRAINTS:
- Content must be professional, persuasive, and actionable
- Use industry-specific terminology and best practices
- Include realistic, credible statistics with proper context
- Each section must be distinct with clear value messaging
- Keep tone consistent with: ${tone}
- Ensure content flows logically from awareness to action

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "title": "Compelling Landing Page Title",
  "headline": "Results-focused hook headline that captures attention",
  "subheading": "Clear subheading with action guidance for visitor",
  "hookType": "results",
  "hero": {
    "title": "Hero section title",
    "description": "Compelling narrative about the transformation/benefit",
    "image_hint": "Description of suggested hero image/video"
  },
  "sections": [
    {
      "title": "Section Title",
      "description": "Detailed section content with benefits and value",
      "sequence": 1
    }
  ],
  "features": {
    "title": "Why Choose Us / Key Benefits",
    "propositions": [
      {"title": "Value Prop 1", "description": "Detailed description"},
      {"title": "Value Prop 2", "description": "Detailed description"},
      {"title": "Value Prop 3", "description": "Detailed description"}
    ]
  },
  "credibility": {
    "description": "Background story of company/author/expert - build trust through experience",
    "backgroundText": "Additional context on credentials, experience, or track record",
    "stats": [
      {"label": "Clients Served", "value": "5000+"},
      {"label": "Years Experience", "value": "15+"},
      {"label": "Success Rate", "value": "94%"},
      {"label": "Industry Award", "value": "Top Rated 2024"}
    ]
  },
  "cta": {
    "text": "Primary call-to-action button text",
    "description": "CTA button description/subtext"
  }
}
"""
    
    // Step 4: Call Gemini API
    def modelName = "gemini-2.5-pro"
    def apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}"
    
    def requestBody = [
        contents: [
            [
                parts: [
                    [text: generationPrompt]
                ]
            ]
        ]
    ]
    
    ec.logger.info("Calling Gemini API for landing page generation...")
    
    URL url = new URL(apiUrl)
    HttpURLConnection conn = (HttpURLConnection) url.openConnection()
    conn.setRequestMethod("POST")
    conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
    conn.setRequestProperty("Accept", "application/json")
    conn.setDoOutput(true)
    conn.setDoInput(true)
    
    // Set timeouts to prevent hanging indefinitely
    // Gemini can take 30-60 seconds for complex prompts
    conn.setConnectTimeout(30000)  // 30 seconds to establish connection
    conn.setReadTimeout(90000)     // 90 seconds to read response
    
    def jsonRequest = JsonOutput.toJson(requestBody)
    conn.outputStream.withWriter { writer ->
        writer.write(jsonRequest)
    }
    
    def responseCode = conn.responseCode
    ec.logger.info("Gemini API Response Code: ${responseCode}")
    
    if (responseCode == 200) {
        def responseText = conn.inputStream.text
        def jsonSlurper = new JsonSlurper()
        def response = jsonSlurper.parseText(responseText)
        
        // Extract the generated text
        def generatedText = response.candidates[0].content.parts[0].text
        
        // Clean up JSON markdown if present
        def cleanedJson = generatedText.replaceAll("```json", "").replaceAll("```", "").trim()
        
        // Parse the cleaned JSON
        def contentData = jsonSlurper.parseText(cleanedJson)
        
        ec.logger.info("Gemini generated content with title: ${contentData.title}")
        
        // Step 5: Generate pseudoId for the landing page
        def pseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
            .parameters([ownerPartyId: ownerPartyId, seqName: 'landingPage'])
            .call()
        def pseudoId = pseudoIdResult.seqNum
        
        // Step 6: Create landing page directly in database
        def landingPageData = [
            title: contentData.title ?: 'Generated Landing Page',
            headline: contentData.headline ?: '',
            subheading: contentData.subheading ?: '',
            hookType: contentData.hookType ?: 'results',
            status: 'DRAFT',
            ownerPartyId: ownerPartyId,
            pseudoId: pseudoId
        ]
        
        def createPageResult = ec.service.sync().name("create#growerp.landing.LandingPage")
            .parameters(landingPageData)
            .call()
        
        def landingPageId = createPageResult.landingPageId
        ec.logger.info("Created landing page: ID=${landingPageId}, pseudoId=${pseudoId}")
        
        // Step 7: Create page sections
        def sectionCount = 0
        def sectionSequence = 1
        
        // Hero section
        if (contentData.hero) {
            def heroPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                .parameters([ownerPartyId: ownerPartyId, seqName: 'pageSection'])
                .call().seqNum
            
            ec.service.sync().name("create#growerp.landing.PageSection")
                .parameters([
                    landingPageId: landingPageId,
                    pseudoId: heroPseudoId,
                    sectionTitle: contentData.hero.title ?: 'Hero',
                    sectionDescription: contentData.hero.description ?: '',
                    sectionSequence: sectionSequence++
                ])
                .call()
            sectionCount++
        }
        
        // Regular sections
        if (contentData.sections && contentData.sections instanceof List) {
            contentData.sections.each { section ->
                def sectionPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                    .parameters([ownerPartyId: ownerPartyId, seqName: 'pageSection'])
                    .call().seqNum
                
                ec.service.sync().name("create#growerp.landing.PageSection")
                    .parameters([
                        landingPageId: landingPageId,
                        pseudoId: sectionPseudoId,
                        sectionTitle: section.title ?: '',
                        sectionDescription: section.description ?: '',
                        sectionSequence: sectionSequence++
                    ])
                    .call()
                sectionCount++
            }
        }
        
        // Features section
        if (contentData.features) {
            def featuresPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                .parameters([ownerPartyId: ownerPartyId, seqName: 'pageSection'])
                .call().seqNum
            
            def featuresContent = contentData.features.propositions?.collect { prop ->
                "${prop.title}: ${prop.description}"
            }?.join(" | ") ?: contentData.features.title
            
            ec.service.sync().name("create#growerp.landing.PageSection")
                .parameters([
                    landingPageId: landingPageId,
                    pseudoId: featuresPseudoId,
                    sectionTitle: contentData.features.title ?: 'Features',
                    sectionDescription: featuresContent ?: '',
                    sectionSequence: sectionSequence++
                ])
                .call()
            sectionCount++
        }
        
        ec.logger.info("Created ${sectionCount} page sections")
        
        // Step 8: Create credibility info
        if (contentData.credibility) {
            def credibilityPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                .parameters([ownerPartyId: ownerPartyId, seqName: 'credibilityInfo'])
                .call().seqNum
            
            ec.service.sync().name("create#growerp.landing.CredibilityInfo")
                .parameters([
                    landingPageId: landingPageId,
                    pseudoId: credibilityPseudoId,
                    creatorBio: contentData.credibility.description ?: '',
                    backgroundText: contentData.credibility.description ?: ''
                ])
                .call()
            
            ec.logger.info("Created credibility info")
        }
        
        // Step 9: Get the complete landing page with all relationships
        def getLandingPageResult = ec.service.sync().name("growerp.100.LandingPageServices100.get#LandingPage")
            .parameters([landingPageId: landingPageId, ownerPartyId: ownerPartyId])
            .call()
        
        // Set output parameters
        context.landingPage = getLandingPageResult.landingPage
        context.sectionsCreated = sectionCount
        
        ec.logger.info("Service complete - returning landing page with ${sectionCount} sections")
        
    } else {
        def errorText = conn.errorStream?.text ?: "Unknown error"
        ec.logger.error("Gemini API error (${responseCode}): ${errorText}")
        ec.message.addError("Failed to generate landing page content: ${errorText}")
    }
    
    conn.disconnect()
    
} catch (Exception e) {
    ec.logger.error("Error in landing page AI generation", e)
    ec.message.addError("Error generating landing page: ${e.message}")
}

return
