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
    ec.logger.info("AI Course Media Generation requested for course: ${courseId}, platform: ${platform}")
    
    // Step 1: Get owner party ID
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
        .call()
    def ownerPartyId = ownerResult.ownerPartyId
    
    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }
    
    // Step 2: Fetch the course details
    def course = ec.entity.find("growerp.course.Course")
        .condition("courseId", courseId)
        .condition("ownerPartyId", ownerPartyId)
        .one()
    
    if (!course) {
        ec.message.addError("Course not found or access denied")
        return
    }
    
    // Step 3: Fetch modules and lessons
    def modules = ec.entity.find("growerp.course.CourseModule")
        .condition("courseId", courseId)
        .orderBy("sequenceNum")
        .list()
    
    def lessonsContent = []
    modules.each { module ->
        def lessons = ec.entity.find("growerp.course.CourseLesson")
            .condition("moduleId", module.moduleId)
            .orderBy("sequenceNum")
            .list()
        lessons.each { lesson ->
            lessonsContent.add("${module.title} - ${lesson.title}: ${lesson.content ?: 'No content'}")
        }
    }
    
    // Step 4: Fetch persona if linked
    def personaInfo = ""
    if (course.targetPersonaId) {
        def persona = ec.entity.find("growerp.marketing.MarketingPersona")
            .condition("personaId", course.targetPersonaId)
            .one()
        if (persona) {
            personaInfo = """
TARGET AUDIENCE:
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
Tone of Voice: ${persona.toneOfVoice}
"""
        }
    }
    
    ec.logger.info("Generating ${platform} content for course: ${course.title}")
    
    // Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    
    // Step 6: Construct platform-specific prompt
    def generationPrompt = buildPromptForPlatform(platform, course, lessonsContent, personaInfo)
    
    ec.logger.info("Calling the configured LLM API for ${platform} content generation...")
    
    // Call the tenant's LLM (gemini, anthropic or openai)
    def jsonSlurper = new JsonSlurper()
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.8, maxOutputTokens: 4096])
    ec.logger.info("Generated ${platform} content successfully")
    
    // Step 9: Determine media type based on platform
    def mediaType = getMediaTypeForPlatform(platform)
    
    // Step 10: Create the CourseMedia entity
    def pseudoIdResult = ec.service.sync().name("growerp.100.GeneralServices100.getNext#PseudoId")
        .parameters([ownerPartyId: ownerPartyId, seqName: 'CourseMedia'])
        .call()
    
    def createMediaResult = ec.service.sync().name("create#growerp.course.CourseMedia")
        .parameters([
            pseudoId: pseudoIdResult.seqNum,
            ownerPartyId: ownerPartyId,
            courseId: courseId,
            moduleId: moduleId,
            lessonId: lessonId,
            platform: platform,
            mediaType: mediaType,
            title: "${course.title} - ${platform} Content",
            generatedContent: generatedText,
            status: 'DRAFT',
            createdDate: ec.user.nowTimestamp,
            lastModifiedDate: ec.user.nowTimestamp
        ])
        .call()
    
    mediaId = createMediaResult.mediaId
    generatedContent = generatedText
    
    ec.message.addMessage("${platform} content generated successfully!")
    
} catch (Exception e) {
    ec.logger.error("Error generating course media with AI", e)
    ec.message.addError("Failed to generate content: ${e.message}")
}

// Helper function to build platform-specific prompts
def buildPromptForPlatform(String platform, course, List lessonsContent, String personaInfo) {
    def courseInfo = """
COURSE INFORMATION:
Title: ${course.title}
Description: ${course.description}
Objectives: ${course.objectives}
Difficulty: ${course.difficulty}
Estimated Duration: ${course.estimatedDuration} minutes

COURSE CONTENT:
${lessonsContent.join('\n')}

${personaInfo}
"""

    switch (platform.toUpperCase()) {
        case 'LINKEDIN':
            return """
Generate a series of 3 LinkedIn posts to promote this course and provide value to the target audience.

${courseInfo}

REQUIREMENTS:
1. Each post should be 150-300 words
2. Use the Pain-News-Prize (PNP) formula:
   - Post 1: Address a PAIN point the course solves
   - Post 2: Share NEWS or insights from the course content
   - Post 3: Offer a PRIZE (value, takeaway, or call-to-action)
3. Include engaging hooks at the start
4. Use line breaks for readability
5. Include relevant hashtags
6. End with a clear call-to-action

RETURN FORMAT: Return the 3 posts separated by "---POST---" markers.
"""

        case 'MEDIUM':
        case 'SUBSTACK':
            return """
Generate a long-form article based on this course content.

${courseInfo}

REQUIREMENTS:
1. Create a compelling headline
2. Write 1500-2500 words
3. Include an engaging introduction
4. Structure with clear headings and subheadings
5. Include actionable takeaways
6. Use examples and stories where relevant
7. End with a summary and call-to-action
8. Make it SEO-friendly

RETURN FORMAT: Return the full article in Markdown format.
"""

        case 'EMAIL':
            return """
Generate a 5-email nurture sequence to promote this course.

${courseInfo}

REQUIREMENTS:
1. Email 1: Welcome & Problem Awareness
2. Email 2: Deep Dive into One Key Concept
3. Email 3: Case Study or Success Story
4. Email 4: Overcome Objections
5. Email 5: Final Call-to-Action

For each email include:
- Subject line
- Preview text
- Email body (200-400 words)
- Call-to-action

RETURN FORMAT: Return each email separated by "---EMAIL---" markers.
"""

        case 'YOUTUBE':
            return """
Generate a YouTube video script based on this course content.

${courseInfo}

REQUIREMENTS:
1. Include a hook (first 15 seconds)
2. Introduction with what viewers will learn
3. Main content broken into clear segments
4. Include timestamps for each section
5. Engagement prompts (like, subscribe, comment)
6. Conclusion with recap and CTA
7. Target duration: 10-15 minutes of spoken content

RETURN FORMAT: Return the full script with timestamps in format [00:00].
"""

        case 'TWITTER':
            return """
Generate a Twitter/X thread based on this course content.

${courseInfo}

REQUIREMENTS:
1. Create a 10-15 tweet thread
2. First tweet should be a hook that makes people want to read more
3. Each tweet should be under 280 characters
4. Use thread numbering (1/, 2/, etc.)
5. Include a strong final tweet with CTA
6. Make it educational and shareable

RETURN FORMAT: Return each tweet on a new line, numbered.
"""

        case 'INAPP':
            return """
Generate an in-app tutorial guide based on this course content.

${courseInfo}

REQUIREMENTS:
1. Create step-by-step instructions
2. Use clear, concise language
3. Include tips and warnings where appropriate
4. Structure for easy scanning
5. Include keyboard shortcuts or quick actions
6. Add troubleshooting tips
7. Format for display in a help sidebar

RETURN FORMAT: Return in Markdown format with clear sections.
"""

        default:
            return """
Generate educational content based on this course.

${courseInfo}

REQUIREMENTS:
1. Create valuable, educational content
2. Make it engaging and actionable
3. Include key takeaways
4. Add a call-to-action

RETURN FORMAT: Return the content in a clear, readable format.
"""
    }
}

// Helper function to determine media type
def getMediaTypeForPlatform(String platform) {
    switch (platform.toUpperCase()) {
        case 'LINKEDIN':
        case 'TWITTER':
            return 'POST'
        case 'MEDIUM':
        case 'SUBSTACK':
            return 'ARTICLE'
        case 'EMAIL':
            return 'SEQUENCE'
        case 'YOUTUBE':
            return 'SCRIPT'
        case 'INAPP':
            return 'TUTORIAL'
        default:
            return 'OTHER'
    }
}
