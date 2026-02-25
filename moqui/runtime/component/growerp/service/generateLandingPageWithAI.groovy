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
    def companyPartyId = ownerResult.companyPartyId
    
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
Generate a COMPLETE, production-ready landing page AND a Business Readiness Assessment in a single comprehensive response.

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

ASSESSMENT REQUIREMENTS (Must be included):
Generate a 15-question "Business Readiness Assessment" divided into two parts:

Part A: 10 Best Practices Questions (Scoring)
- Generate 10 specific MultipleChoice questions that determine if the user follows industry best practices.
- Each question must have 2-4 options with a score (0-100) indicating readiness.
- High scores indicate good practices; low scores indicate needs improvement.

Part B: 5 Sales Qualification Questions (Specific Format)
- Question 1: "Which best describes your current situation?" (Options: Stagnant, Slow Growth, Rapid Growth, etc.)
- Question 2: "Which is the most important desired outcome for you to achieve in the next 90 days?" (Options: Increase revenue, Improve efficiency, etc.)
- Question 3: "What is the obstacle that you think is stopping you, or what have you tried that hasn't worked in the past?" (Options: specific obstacles)
- Question 4: "Which solution do you think would suit you best?" (Options MUST hint at budget: "Education/Training", "One-to-one Coaching", "Software", "I want someone to do it all for me")
- Question 5: "Is there anything else that you think we need to know about?" (Type: Text, No options)

SCORING THRESHOLDS:
- Define 3 scoring ranges (Critical, Needs Work, Ready) based on the total possible score from Part A.

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
{
  "title": "Compelling Landing Page Title",
  "headline": "Results-focused hook headline",
  "subheading": "Clear subheading",
  "hookType": "results",
  "hero": {
    "title": "Hero section title",
    "description": "Compelling narrative",
    "image_hint": "Visual description"
  },
  "sections": [
    { "title": "Section Title", "description": "Content", "sequence": 1 }
  ],
  "features": {
    "title": "Key Benefits",
    "propositions": [
      {"title": "Prop 1", "description": "Desc"}
    ]
  },
  "credibility": {
    "description": "Author background",
    "backgroundText": "Credentials",
    "stats": [
      {"label": "Stat Label", "value": "Stat Value"}
    ]
  },
  "assessment": {
    "title": "Assessment Title",
    "description": "Assessment Description",
    "questions": [
      {
        "text": "Question Text",
        "description": "Short description",
        "type": "MultipleChoice", 
        "sequence": 1,
        "options": [
          {"text": "Option Text", "score": 10, "sequence": 1}
        ]
      }
    ],
    "scoringThresholds": [
       {"minScore": 0, "maxScore": 30, "status": "Critical", "description": "Urgent help needed"},
       {"minScore": 31, "maxScore": 70, "status": "NeedsWork", "description": "Improvement needed"},
       {"minScore": 71, "maxScore": 100, "status": "Ready", "description": "Ready for growth"}
    ]
  },
  "cta": {
    "text": "Start Assessment",
    "description": "Take the quiz now"
  }
}
"""
    
    // Step 4: Call Gemini API
    def modelName = "gemini-2.5-flash"
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
    
    def jsonRequest = JsonOutput.toJson(requestBody)
    int maxRetries = 3
    boolean apiSuccess = false

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
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
    
    conn.outputStream.withWriter { writer ->
        writer.write(jsonRequest)
    }
    
    def responseCode = conn.responseCode
    ec.logger.info("Gemini API Response Code: ${responseCode}${attempt > 0 ? ' (attempt ' + (attempt + 1) + ')' : ''}")

    if (responseCode == 429 && attempt < maxRetries) {
        def waitSeconds = (attempt + 1) * 10  // 10s, 20s, 30s
        ec.logger.warn("Gemini API rate limited (429), waiting ${waitSeconds}s before retry ${attempt + 1}/${maxRetries}...")
        conn.disconnect()
        Thread.sleep(waitSeconds * 1000L)
        continue
    }

    if (responseCode == 200) {
        apiSuccess = true
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
            companyPartyId: companyPartyId,
            pseudoId: pseudoId,
            ctaActionType: 'assessment' // Default to assessment for this flow (lowercase to match FTL template)
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
            
            def credResult = ec.service.sync().name("create#growerp.landing.CredibilityInfo")
                .parameters([
                    landingPageId: landingPageId,
                    pseudoId: credibilityPseudoId,
                    creatorBio: contentData.credibility.description ?: '',
                    backgroundText: contentData.credibility.backgroundText ?: ''
                ])
                .call()
            
            def credibilityInfoId = credResult.credibilityInfoId
            
            // Create stats
            if (contentData.credibility.stats) {
                contentData.credibility.stats.eachWithIndex { stat, index ->
                     def statPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                        .parameters([ownerPartyId: ownerPartyId, seqName: 'credibilityStatistic'])
                        .call().seqNum
                        
                     ec.service.sync().name("create#growerp.landing.CredibilityStatistic")
                        .parameters([
                            credibilityInfoId: credibilityInfoId,
                            pseudoId: statPseudoId,
                            statistic: "${stat.label}: ${stat.value}",
                            sequence: index + 1
                        ])
                        .call()
                }
            }
            
            ec.logger.info("Created credibility info")
        }
        
        // Step 9: Create Assessment
        if (contentData.assessment) {
            def assessmentPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                .parameters([ownerPartyId: ownerPartyId, seqName: 'assessment'])
                .call().seqNum
                
            def assessmentResult = ec.service.sync().name("create#growerp.assessment.Assessment")
                .parameters([
                    pseudoId: assessmentPseudoId,
                    ownerPartyId: ownerPartyId,
                    assessmentName: contentData.assessment.title ?: 'Business Readiness Assessment',
                    description: contentData.assessment.description ?: '',
                    status: 'Active'
                ])
                .call()
            
            def assessmentId = assessmentResult.assessmentId
            
            // Link Assessment to Landing Page
            ec.service.sync().name("update#growerp.landing.LandingPage")
                .parameters([landingPageId: landingPageId, ctaAssessmentId: assessmentId])
                .call()
                
            // Create Questions
            if (contentData.assessment.questions) {
                contentData.assessment.questions.each { q ->
                    def questionPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                        .parameters([ownerPartyId: ownerPartyId, seqName: 'assessmentQuestion'])
                        .call().seqNum
                        
                    def questionResult = ec.service.sync().name("create#growerp.assessment.AssessmentQuestion")
                        .parameters([
                            assessmentId: assessmentId,
                            pseudoId: questionPseudoId,
                            questionSequence: q.sequence,
                            questionType: q.type ?: 'MultipleChoice',
                            questionText: q.text,
                            questionDescription: q.description,
                            isRequired: 'Y'
                        ])
                        .call()
                        
                    def questionId = questionResult.assessmentQuestionId
                    
                    // Create Options
                    if (q.options) {
                        q.options.each { opt ->
                            def optionPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                                .parameters([ownerPartyId: ownerPartyId, seqName: 'assessmentQuestionOption'])
                                .call().seqNum
                                
                            ec.service.sync().name("create#growerp.assessment.AssessmentQuestionOption")
                                .parameters([
                                    assessmentQuestionId: questionId,
                                    assessmentId: assessmentId,
                                    pseudoId: optionPseudoId,
                                    optionSequence: opt.sequence,
                                    optionText: opt.text,
                                    optionScore: opt.score
                                ])
                                .call()
                        }
                    }
                }
            }
            
            // Create Scoring Thresholds
            if (contentData.assessment.scoringThresholds) {
                contentData.assessment.scoringThresholds.each { threshold ->
                    def thresholdPseudoId = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
                        .parameters([ownerPartyId: ownerPartyId, seqName: 'scoringThreshold'])
                        .call().seqNum
                        
                    ec.service.sync().name("create#growerp.assessment.ScoringThreshold")
                        .parameters([
                            assessmentId: assessmentId,
                            pseudoId: thresholdPseudoId,
                            minScore: threshold.minScore,
                            maxScore: threshold.maxScore,
                            leadStatus: threshold.status,
                            description: threshold.description
                        ])
                        .call()
                }
            }
            ec.logger.info("Created assessment with ${contentData.assessment.questions?.size() ?: 0} questions")
        }
        
        // Step 10: Get the complete landing page with all relationships
        def getLandingPageResult = ec.service.sync().name("growerp.100.LandingPageServices100.get#LandingPage")
            .parameters([landingPageId: landingPageId, ownerPartyId: ownerPartyId])
            .call()
        
        // Set output parameters
        context.landingPage = getLandingPageResult.landingPage
        context.sectionsCreated = sectionCount
        
        ec.logger.info("Service complete - returning landing page with ${sectionCount} sections")
        conn.disconnect()
        break

    } else {
        def errorText = conn.errorStream?.text ?: "Unknown error"
        ec.logger.error("Gemini API error (${responseCode}): ${errorText}")
        ec.message.addError("Failed to generate landing page content: ${errorText}")
        conn.disconnect()
        break
    }
    } // end retry loop

} catch (Exception e) {
    ec.logger.error("Error in landing page AI generation", e)
    ec.message.addError("Error generating landing page: ${e.message}")
}

return
