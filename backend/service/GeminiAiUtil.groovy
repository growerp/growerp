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

/**
 * Unified Gemini AI API utility for GrowERP.
 * 
 * Usage in other scripts:
 *   def binding = new Binding([ec: ec])
 *   def shell = new GroovyShell(binding)
 *   def aiUtil = shell.evaluate(new File("component://growerp/service/GeminiAiUtil.groovy"))
 *   def result = aiUtil.callGeminiApi(ec, prompt, [temperature: 0.7])
 * 
 * Or via service call:
 *   ec.service.sync().name("growerp.100.GeneralServices100.call#GeminiApi")
 *       .parameters([prompt: prompt, options: [temperature: 0.7]])
 *       .call()
 */

class GeminiAiUtil {
    
    static final String DEFAULT_MODEL = "gemini-3.5-flash"
    static final String API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    /**
     * Call Gemini API with a prompt and optional configuration.
     * 
     * @param ec ExecutionContext from Moqui
     * @param prompt The text prompt to send to Gemini
     * @param options Optional map with: apiKey, model, temperature, topK, topP, maxOutputTokens, jsonMode
     * @return The generated text response (cleaned of markdown code blocks if JSON)
     * @throws Exception if API key not found or API call fails
     */
    static String callGeminiApi(def ec, String prompt, Map options = [:]) {
        // Get API key from options (batch/cron callers), user preference or environment
        def apiKey = options.apiKey ?: ec.user.getPreference("GEMINI_API_KEY")
        if (apiKey == null || apiKey.isEmpty()) {
            apiKey = System.getenv("GEMINI_API_KEY")
        }
        if (apiKey == null || apiKey.isEmpty()) {
            throw new Exception("GEMINI_API_KEY not configured. Set in user preferences or environment.")
        }
        
        // Configuration with defaults
        def model = options.model ?: ec.user.getPreference("GEMINI_MODEL") ?: System.getenv("GEMINI_MODEL") ?: System.getProperty("GEMINI_MODEL") ?: DEFAULT_MODEL
        def temperature = options.temperature ?: 0.7
        def topK = options.topK ?: 40
        def topP = options.topP ?: 0.95
        def maxOutputTokens = options.maxOutputTokens ?: 4096
        def jsonMode = options.jsonMode ?: false
        
        // Build API URL
        def apiUrl = "${API_BASE_URL}/${model}:generateContent?key=${apiKey}"
        
        ec.logger.info("Calling Gemini API with model: ${model}")
        
        // Build request body
        def requestMap = [
            contents: [
                [
                    parts: [
                        [text: prompt]
                    ]
                ]
            ],
            generationConfig: [
                temperature: temperature,
                topK: topK,
                topP: topP,
                maxOutputTokens: maxOutputTokens
            ]
        ]
        
        // Add JSON mode if requested (for newer models that support it)
        if (jsonMode) {
            requestMap.generationConfig.responseMimeType = "application/json"
        }
        
        def requestBody = JsonOutput.toJson(requestMap)
        
        // Make HTTP request
        def connection = new URL(apiUrl).openConnection() as HttpURLConnection
        connection.setRequestMethod("POST")
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setDoOutput(true)
        connection.setConnectTimeout(30000)  // 30 seconds
        connection.setReadTimeout(120000)    // 2 minutes for complex prompts
        
        connection.outputStream.withWriter("UTF-8") { writer ->
            writer.write(requestBody)
        }
        
        def responseCode = connection.responseCode
        ec.logger.info("Gemini API response code: ${responseCode}")
        
        if (responseCode != 200) {
            def errorStream = connection.errorStream
            def errorText = errorStream ? errorStream.text : "No error details available"
            ec.logger.error("Gemini API error (${responseCode}): ${errorText}")
            throw new Exception("Gemini API error (${responseCode}): ${errorText}")
        }
        
        def responseText = connection.inputStream.text
        def jsonSlurper = new JsonSlurper()
        def geminiResponse = jsonSlurper.parseText(responseText)
        
        // Extract generated text
        def generatedText = geminiResponse.candidates[0]?.content?.parts[0]?.text
        
        if (generatedText == null) {
            ec.logger.error("No content generated by Gemini API")
            throw new Exception("Gemini API returned no content")
        }
        
        ec.logger.info("Generated ${generatedText.length()} characters from Gemini")
        
        // Clean up markdown code blocks if present (common in JSON responses)
        generatedText = cleanJsonResponse(generatedText)
        
        return generatedText
    }
    
    /**
     * Clean JSON response by removing markdown code blocks.
     */
    static String cleanJsonResponse(String text) {
        if (text == null) return null
        return text
            .replaceAll(/```json\s*/, '')
            .replaceAll(/```\s*$/, '')
            .replaceAll(/^```\s*/, '')
            .trim()
    }
    
    /**
     * Parse JSON from AI response safely.
     */
    static def parseJsonResponse(String text) {
        def cleaned = cleanJsonResponse(text)
        def jsonSlurper = new JsonSlurper()
        return jsonSlurper.parseText(cleaned)
    }
    
    /**
     * Generate a platform-specific message from a campaign template.
     * 
     * @param ec ExecutionContext
     * @param campaignTemplate The base campaign message template
     * @param platform The target platform (TWITTER, LINKEDIN, EMAIL, etc.)
     * @param actionType The action type (post_tweet, send_dms, etc.)
     * @return A platform-optimized message
     */
    static String generatePlatformMessage(def ec, String campaignTemplate, String platform, String actionType) {
        def prompt = """
Adapt the following marketing message for the ${platform} platform.

ORIGINAL MESSAGE:
${campaignTemplate}

ACTION TYPE: ${actionType}

PLATFORM REQUIREMENTS:
${getPlatformRequirements(platform, actionType)}

Return ONLY the adapted message text, no explanations or formatting.
Keep the core message but optimize for the platform's style and constraints.
"""
        
        return callGeminiApi(ec, prompt, [temperature: 0.6, maxOutputTokens: 1024])
    }

    /**
     * Polish the tone of an already-personalised outreach message draft (e.g. one produced by
     * {name}/{company}/{title} template substitution) without altering its facts or length.
     *
     * @param ec ExecutionContext
     * @param draftMessage The already-personalised message body to polish
     * @param platform The target platform (LINKEDIN, EMAIL, etc.)
     * @param recipientName Optional recipient name for context
     * @param recipientCompany Optional recipient company for context
     * @param recipientTitle Optional recipient job title for context
     * @return The polished message
     */
    static String polishMessage(def ec, String draftMessage, String platform,
            String recipientName = null, String recipientCompany = null, String recipientTitle = null) {
        def prompt = """
Improve the tone and flow of the following already-personalized ${platform} outreach message.
Keep it roughly the same length and keep all specific facts (names, companies, titles) intact.
Do not add claims that aren't already present. Do not add a greeting/sign-off if the draft doesn't have one.

RECIPIENT: ${recipientName ?: '(unknown)'}${recipientTitle ? ' - ' + recipientTitle : ''}${recipientCompany ? ' at ' + recipientCompany : ''}

DRAFT MESSAGE:
${draftMessage}

Return ONLY the revised message text, no explanations or markdown.
"""

        return callGeminiApi(ec, prompt, [temperature: 0.5, maxOutputTokens: 1024])
    }

    /**
     * Get platform-specific requirements for message adaptation.
     */
    private static String getPlatformRequirements(String platform, String actionType) {
        switch (platform.toUpperCase()) {
            case 'TWITTER':
                if (actionType == 'post_tweet') {
                    return "- Maximum 280 characters\n- Use hashtags sparingly (1-2 max)\n- Engaging and concise\n- Can include emoji"
                } else {
                    return "- Professional but casual tone\n- Keep under 500 characters for DMs\n- Start with personalization"
                }
            case 'LINKEDIN':
                return "- Professional tone\n- Can be longer (up to 3000 chars for connection notes, more for messages)\n- Include value proposition\n- Reference mutual connections or interests if mentioned"
            case 'EMAIL':
                return "- Professional tone\n- Clear call-to-action\n- Include greeting and sign-off\n- Keep concise but complete"
            case 'SUBSTACK':
                return "- Thoughtful, writer-style tone\n- Can be conversational\n- For notes: keep under 500 chars\n- For comments: be engaging and add value"
            default:
                return "- Professional and concise\n- Clear message\n- Include call-to-action"
        }
    }

    /**
     * Adapt one platform-neutral MasterContent piece for a specific platform,
     * honouring the content type (POSTING / ARTICLE / MESSAGE) and the
     * per-platform adaptation rules (see plans/marketing-content-plan.md).
     *
     * @param ec ExecutionContext
     * @param title The master content title/headline
     * @param body The canonical platform-neutral body
     * @param platform Target platform: LINKEDIN, TWITTER, FACEBOOK, MEDIUM, SUBSTACK, EMAIL
     * @param contentType POSTING | ARTICLE | MESSAGE
     * @param callToAction Optional CTA text
     * @param targetUrl Optional link (withheld for LinkedIn/DM by the rules below)
     * @return The adapted, ready-to-publish text for that platform
     */
    static String generateAdaptedContent(def ec, String title, String body, String platform,
            String contentType, String callToAction = null, String targetUrl = null) {
        def prompt = """
Adapt the following platform-neutral marketing content for the ${platform} platform.
Keep the core message and facts intact; rewrite tone, length and format to fit the platform.

TITLE: ${title ?: '(none)'}
CONTENT TYPE: ${contentType}
CALL TO ACTION: ${callToAction ?: '(none)'}
LINK: ${targetUrl ?: '(none)'}

MASTER CONTENT:
${body}

PLATFORM + FORMAT REQUIREMENTS:
${getAdaptationRules(platform, contentType, targetUrl)}

Return ONLY the adapted content text, no explanations, no markdown code fences.
"""
        return callGeminiApi(ec, prompt, [temperature: 0.7, maxOutputTokens: 4096])
    }

    /**
     * Per-platform + per-content-type adaptation rules.
     * Encodes the reference table in plans/marketing-content-plan.md.
     */
    private static String getAdaptationRules(String platform, String contentType, String targetUrl) {
        def hasUrl = targetUrl != null && !targetUrl.trim().isEmpty()
        switch (platform.toUpperCase()) {
            case 'LINKEDIN':
                if (contentType == 'MESSAGE') {
                    return "- 1:1 DM tone: short, human, specific\n- Under ~400 characters\n- End on a question\n- Include NO URL (we share the link only after they reply)"
                }
                return "- Professional post, up to ~1300 characters\n- Short paragraphs, 1-2 relevant emojis\n- 3-5 topical hashtags at the end\n- ${hasUrl ? 'Include the link near the end' : 'No link needed'}\n- End with an engaging question"
            case 'TWITTER':
                return "- Thread of tweets, each MAX 280 characters, separated by a blank line\n- Hook in the first tweet\n- 1-2 hashtags total\n- ${hasUrl ? 'Put the link in the last tweet' : 'No link needed'}"
            case 'FACEBOOK':
                return "- Conversational, community tone\n- ~400 characters plus a link preview\n- Minimal hashtags\n- ${hasUrl ? 'End with the link (it renders a preview)' : 'No link needed'}"
            case 'MEDIUM':
                return "- Long-form ARTICLE, 700-1500 words\n- SEO-friendly headline as the first line\n- Sub-headings and short paragraphs\n- ${hasUrl ? 'Include the link inline where natural' : 'No link needed'}"
            case 'SUBSTACK':
                return "- Newsletter voice, thoughtful and conversational\n- ${contentType == 'ARTICLE' ? 'Full issue with intro, body, sign-off' : 'Short note under 500 characters'}\n- ${hasUrl ? 'Include a subscribe/CTA link' : 'No link needed'}"
            case 'EMAIL':
                return "- ${contentType == 'MESSAGE' ? '1:1 email under ~120 words' : 'Broadcast newsletter, 200-400 words'}\n- Clear greeting and a one-line sign-off (Hans, GrowERP)\n- Single clear call-to-action\n- ${hasUrl ? 'Include the link once' : 'No link needed'}"
            default:
                return "- Professional and concise\n- Clear single call-to-action"
        }
    }
}

// Return the utility class for use by other scripts
return GeminiAiUtil
