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
    
    static final String DEFAULT_MODEL = "gemini-3.7-flash"
    static final String API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"
    static final String ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
    static final String ANTHROPIC_VERSION = "2023-06-01"
    static final String OPENAI_URL = "https://api.openai.com/v1/chat/completions"
    static final int MAX_RETRIES = 3

    /** Provider serving a model id, for rows stored before aiProvider existed. */
    static String providerForModel(String model) {
        if (!model) return "gemini"
        if (model.startsWith("claude")) return "anthropic"
        if (model.startsWith("gpt") || model ==~ /^o\d.*/) return "openai"
        return "gemini"
    }

    /**
     * Resolve which model to use and which provider serves it. Both always come from the SAME
     * level: a tenant that picked only a model must not inherit the system default's provider,
     * or its model gets posted to the wrong endpoint. Precedence: an explicit model (caller
     * override) > the tenant's SystemSettings (System Setup) > the GrowERP wide SystemDefault
     * (Support app -> System Defaults) > a per-user Moqui preference / env var / system
     * property > DEFAULT_MODEL.
     */
    static Map resolveModelConfig(def ec, String ownerPartyId, String explicitModel = null,
            String explicitProvider = null) {
        if (explicitModel) {
            return [model: explicitModel, provider: explicitProvider ?: providerForModel(explicitModel)]
        }
        if (ownerPartyId) {
            def settings = ec.entity.find("growerp.general.SystemSettings")
                .condition("ownerPartyId", ownerPartyId).one()
            if (settings?.aiModelName) {
                String tenantModel = settings.aiModelName as String
                return [model: tenantModel,
                        provider: (settings.aiProvider ?: providerForModel(tenantModel)) as String]
            }
        }
        def sysDefault = ec.entity.find("growerp.general.SystemDefault")
            .condition("defaultId", "SYSTEM").one()
        if (sysDefault?.aiModelName) {
            String defaultModel = sysDefault.aiModelName as String
            return [model: defaultModel,
                    provider: (sysDefault.aiProvider ?: providerForModel(defaultModel)) as String]
        }
        String envModel = ec.user.getPreference("GEMINI_MODEL") ?: System.getenv("GEMINI_MODEL") ?:
            System.getProperty("GEMINI_MODEL") ?: DEFAULT_MODEL
        return [model: envModel, provider: explicitProvider ?: providerForModel(envModel)]
    }

    /** Model name only; see resolveModelConfig for the full precedence. */
    static String resolveModel(def ec, String ownerPartyId, String explicitModel = null) {
        return resolveModelConfig(ec, ownerPartyId, explicitModel).model as String
    }

    /**
     * The API key for [provider]: an explicit key (batch/cron callers) > this tenant's LlmConfig
     * row for that provider (entered in System Setup) > the environment. Returns '' when none.
     */
    static String resolveApiKey(def ec, String ownerPartyId, String provider, String explicitKey = null) {
        if (explicitKey) return explicitKey
        if (ownerPartyId) {
            def llmConfig = ec.entity.find("growerp.general.LlmConfig")
                .condition("ownerPartyId", ownerPartyId).condition("llmProvider", provider).one()
            if (llmConfig?.apiKey) return llmConfig.apiKey as String
        }
        switch (provider) {
            case "anthropic": return System.getenv("ANTHROPIC_API_KEY") ?: ""
            case "openai": return System.getenv("OPENAI_API_KEY") ?: ""
            default:
                return ec.user.getPreference("GEMINI_API_KEY") ?: System.getenv("GEMINI_API_KEY") ?:
                    System.getenv("GOOGLE_API_KEY") ?: ""
        }
    }

    /**
     * Send a prompt to whichever LLM the tenant configured.
     *
     * @param ec ExecutionContext from Moqui
     * @param prompt The text prompt to send
     * @param options Optional map with: apiKey, model, provider, ownerPartyId, temperature,
     *        topK, topP, maxOutputTokens, jsonMode
     * @return The generated text (markdown code fences stripped)
     * @throws Exception if no API key is configured or the API call fails
     */
    static String callLlmApi(def ec, String prompt, Map options = [:]) {
        String ownerPartyId = options.ownerPartyId as String
        Map modelConfig = resolveModelConfig(ec, ownerPartyId, options.model as String,
            options.provider as String)
        String model = modelConfig.model as String
        String provider = modelConfig.provider as String
        String apiKey = resolveApiKey(ec, ownerPartyId, provider, options.apiKey as String)
        if (!apiKey) {
            throw new Exception("No API key configured for LLM provider '${provider}'. " +
                "Add it in System Setup -> AI Settings.")
        }
        if (hasOwnApiKey(ec, ownerPartyId, provider, options.apiKey as String)) {
            checkOwnAllowance(ec, ownerPartyId)
        } else {
            checkMonthlyAllowance(ec, ownerPartyId)
        }

        ec.logger.info("Calling ${provider} API with model: ${model}")
        Map result
        switch (provider) {
            case "anthropic": result = callAnthropic(ec, prompt, model, apiKey, options); break
            case "openai": result = callOpenAi(ec, prompt, model, apiKey, options); break
            default: result = callGemini(ec, prompt, model, apiKey, options)
        }
        String generatedText = result.text as String
        ec.logger.info("Generated ${generatedText.length()} characters from ${provider}")
        logUsage(ec, ownerPartyId, provider, model, result, options)

        // Clean up markdown code blocks if present (common in JSON responses)
        return cleanJsonResponse(generatedText)
    }

    /**
     * Historical entry point, kept so the existing callers keep working. Dispatches on the
     * tenant's configured provider, which is not necessarily Gemini.
     */
    static String callGeminiApi(def ec, String prompt, Map options = [:]) {
        return callLlmApi(ec, prompt, options)
    }

    /**
     * POST a JSON body and return the response text, throwing with the API's own error message
     * on a non-200. A 429 (rate limited) is retried up to MAX_RETRIES times with a growing wait.
     */
    private static String postJson(def ec, String urlText, Map headers, String requestBody, String label) {
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            def connection = new URL(urlText).openConnection() as HttpURLConnection
            connection.setRequestMethod("POST")
            connection.setRequestProperty("Content-Type", "application/json")
            headers.each { key, value -> connection.setRequestProperty(key as String, value as String) }
            connection.setDoOutput(true)
            connection.setConnectTimeout(30000)  // 30 seconds
            connection.setReadTimeout(120000)    // 2 minutes for complex prompts

            connection.outputStream.withWriter("UTF-8") { writer -> writer.write(requestBody) }

            def responseCode = connection.responseCode
            ec.logger.info("${label} API response code: ${responseCode}")
            if (responseCode == 200) return connection.inputStream.text

            def errorStream = connection.errorStream
            def errorText = errorStream ? errorStream.text : "No error details available"
            connection.disconnect()
            if (responseCode == 429 && attempt < MAX_RETRIES) {
                int waitSeconds = (attempt + 1) * 10  // 10s, 20s, 30s
                ec.logger.warn("${label} API rate limited (429), waiting ${waitSeconds}s before " +
                    "retry ${attempt + 1}/${MAX_RETRIES}")
                Thread.sleep(waitSeconds * 1000L)
                continue
            }
            ec.logger.error("${label} API error (${responseCode}): ${errorText}")
            throw new Exception("${label} API error (${responseCode}): ${errorText}")
        }
        throw new Exception("${label} API still rate limited after ${MAX_RETRIES} retries")
    }

    private static Map callGemini(def ec, String prompt, String model, String apiKey, Map options) {
        def requestMap = [
            contents: [[parts: [[text: prompt]]]],
            generationConfig: [
                temperature: options.temperature ?: 0.7,
                topK: options.topK ?: 40,
                topP: options.topP ?: 0.95,
                maxOutputTokens: options.maxOutputTokens ?: 4096
            ]
        ]
        // JSON mode, for the newer models that support it
        if (options.jsonMode) requestMap.generationConfig.responseMimeType = "application/json"

        def responseText = postJson(ec, "${API_BASE_URL}/${model}:generateContent?key=${apiKey}",
            [:], JsonOutput.toJson(requestMap), "Gemini")
        def geminiResponse = new JsonSlurper().parseText(responseText)
        def generatedText = geminiResponse.candidates[0]?.content?.parts[0]?.text
        if (generatedText == null) {
            ec.logger.error("No content generated by Gemini API")
            throw new Exception("Gemini API returned no content")
        }
        def usage = geminiResponse.usageMetadata
        return [text: generatedText,
                tokensIn: (usage?.promptTokenCount ?: 0) as int,
                tokensOut: (usage?.candidatesTokenCount ?: 0) as int,
                tokensTotal: (usage?.totalTokenCount ?: 0) as int]
    }

    private static Map callAnthropic(def ec, String prompt, String model, String apiKey, Map options) {
        // No temperature/topP/topK: the current Claude models reject them with a 400, so the
        // options the Gemini callers pass are deliberately dropped here.
        def requestMap = [
            model: model,
            max_tokens: options.maxOutputTokens ?: 4096,
            messages: [[role: "user", content: prompt]]
        ]
        def responseText = postJson(ec, ANTHROPIC_URL,
            ["x-api-key": apiKey, "anthropic-version": ANTHROPIC_VERSION],
            JsonOutput.toJson(requestMap), "Anthropic")
        def response = new JsonSlurper().parseText(responseText)

        // A declined request is a 200 with an empty content list, not an error status
        if (response.stop_reason == "refusal") {
            String category = response.stop_details?.category ?: "unspecified"
            ec.logger.error("Anthropic declined the request, category: ${category}")
            throw new Exception("Anthropic declined this request (category ${category}). " +
                "Rephrase the prompt or use another model.")
        }
        def textBlock = response.content?.find { it.type == "text" }
        if (textBlock?.text == null) {
            ec.logger.error("No content generated by Anthropic API, stop reason: ${response.stop_reason}")
            throw new Exception("Anthropic API returned no content")
        }
        int tokensIn = (response.usage?.input_tokens ?: 0) as int
        int tokensOut = (response.usage?.output_tokens ?: 0) as int
        return [text: textBlock.text, tokensIn: tokensIn, tokensOut: tokensOut,
                tokensTotal: tokensIn + tokensOut]
    }

    private static Map callOpenAi(def ec, String prompt, String model, String apiKey, Map options) {
        def requestMap = [
            model: model,
            messages: [[role: "user", content: prompt]],
            temperature: options.temperature ?: 0.7,
            max_tokens: options.maxOutputTokens ?: 4096,
            stream: false
        ]
        if (options.jsonMode) requestMap.response_format = [type: "json_object"]

        def responseText = postJson(ec, OPENAI_URL, ["Authorization": "Bearer ${apiKey}".toString()],
            JsonOutput.toJson(requestMap), "OpenAI")
        def response = new JsonSlurper().parseText(responseText)
        def generatedText = response.choices[0]?.message?.content
        if (generatedText == null) {
            ec.logger.error("No content generated by OpenAI API")
            throw new Exception("OpenAI API returned no content")
        }
        def usage = response.usage
        return [text: generatedText,
                tokensIn: (usage?.prompt_tokens ?: 0) as int,
                tokensOut: (usage?.completion_tokens ?: 0) as int,
                tokensTotal: (usage?.total_tokens ?: 0) as int]
    }
    
    /** True when this call is paid for with the tenant's own key, not the GrowERP system key. */
    private static boolean hasOwnApiKey(def ec, String ownerPartyId, String provider, String explicitKey) {
        if (explicitKey) return true
        if (!ownerPartyId) return false
        def llmConfig = ec.entity.find("growerp.general.LlmConfig")
            .condition("ownerPartyId", ownerPartyId).condition("llmProvider", provider).one()
        return llmConfig?.apiKey ? true : false
    }

    /** System LLM tokens this owner used since the first of the current calendar month. */
    static long monthlyTokensUsed(def ec, String ownerPartyId) {
        def cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.DAY_OF_MONTH, 1)
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        def startOfMonth = new java.sql.Timestamp(cal.getTimeInMillis())
        long used = 0
        // grouped view: one row per owner, summed in SQL
        ec.entity.find("moqui.adk.AdkOwnerTokenSummary")
            .selectField("ownerPartyId").selectField("tokensTotal")
            .condition("ownerPartyId", ownerPartyId)
            .condition("actionTime", org.moqui.entity.EntityCondition.GREATER_THAN_EQUAL_TO,
                startOfMonth)
            .disableAuthz().list().each { used += (it.tokensTotal ?: 0) as long }
        return used
    }

    /**
     * Stop generating on the GrowERP system key once this tenant used up its free monthly
     * allowance (SystemDefault.llmMonthlyTokenLimit, 0/empty = unlimited). Same rule the ADK
     * agent gate applies in growerp.100.AdkGovernanceServices.govern#AgentAction.
     * Not enforced for calls without a real tenant (system tasks, ownerPartyId '_NA_').
     */
    private static void checkMonthlyAllowance(def ec, String ownerPartyId) {
        if (!ownerPartyId || ownerPartyId == "_NA_") return
        // a per tenant override (Support app owner list) wins over the system wide default
        def settings = ec.entity.find("growerp.general.SystemSettings")
            .condition("ownerPartyId", ownerPartyId).one()
        def limitValue = settings?.llmMonthlyTokenLimit
        if (limitValue == null) {
            def sysDefault = ec.entity.find("growerp.general.SystemDefault")
                .condition("defaultId", "SYSTEM").one()
            limitValue = sysDefault?.llmMonthlyTokenLimit
        }
        long limit = (limitValue ?: 0) as long
        if (limit <= 0) return
        long used
        try {
            used = monthlyTokensUsed(ec, ownerPartyId)
        } catch (Throwable t) {
            // moqui-adk absent: nothing is metered, so nothing can be over the limit
            ec.logger.warn("LLM allowance check skipped: ${t.message}")
            return
        }
        if (used >= limit) {
            throw new Exception("Free monthly AI allowance used (${used} of ${limit} tokens). " +
                "Please add your own API Key in System Setup -> AI Settings.")
        }
    }

    /**
     * Cap the tenant set on its own key (SystemSettings.ownTokenLimit, null/0 = no cap), so a
     * tenant generating on its own API key can limit what it spends. Same rule the ADK agent
     * gate applies in growerp.100.AdkGovernanceServices.govern#AgentAction.
     */
    private static void checkOwnAllowance(def ec, String ownerPartyId) {
        if (!ownerPartyId || ownerPartyId == "_NA_") return
        def settings = ec.entity.find("growerp.general.SystemSettings")
            .condition("ownerPartyId", ownerPartyId).one()
        long limit = (settings?.ownTokenLimit ?: 0) as long
        if (limit <= 0) return
        long used
        try {
            used = monthlyTokensUsed(ec, ownerPartyId)
        } catch (Throwable t) {
            // moqui-adk absent: nothing is metered, so nothing can be over the limit
            ec.logger.warn("LLM own limit check skipped: ${t.message}")
            return
        }
        if (used >= limit) {
            throw new Exception("Own monthly AI token limit reached (${used} of ${limit} tokens). " +
                "Raise or clear it in System Setup -> AI Settings.")
        }
    }

    /**
     * Record what this LLM call cost, so the Support app can show per tenant token use.
     * Guarded: a no-op when the moqui-adk component is absent, and never fails the caller.
     * Own transaction: the tokens are spent even when the calling service later rolls back.
     */
    private static void logUsage(def ec, String ownerPartyId, String provider, String model,
            Map result, Map options) {
        try {
            String artifactName = null
            try { artifactName = ec.artifactExecution.peek()?.getName() } catch (Throwable ignored) { }
            ec.service.sync().name("create#moqui.adk.AdkActionLog")
                .parameters([ownerPartyId: ownerPartyId,
                             serviceName: options.purpose ?: artifactName ?: "llm",
                             toolName: "${provider}:${model}".toString(),
                             verbClass: "ai", decision: "allowed",
                             tokensIn: result.tokensIn ?: 0, tokensOut: result.tokensOut ?: 0,
                             tokensTotal: result.tokensTotal ?: 0,
                             actionTime: ec.user.nowTimestamp])
                .disableAuthz().requireNewTransaction(true).call()
        } catch (Throwable t) {
            ec.logger.warn("LLM usage logging skipped: ${t.message}")
        }
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
     * @param ownerPartyId Optional tenant id, used to resolve SystemSettings.aiModelName
     * @return A platform-optimized message
     */
    static String generatePlatformMessage(def ec, String campaignTemplate, String platform, String actionType,
            String ownerPartyId = null) {
        def prompt = """
Adapt the following marketing message for the ${platform} platform.

ORIGINAL MESSAGE:
${campaignTemplate}

ACTION TYPE: ${actionType}

PLATFORM REQUIREMENTS:
${getPlatformRequirements(platform, actionType)}

PERSONALISATION TOKENS:
Refer to the recipient with these tokens, which are substituted per recipient when the
message is sent: {firstName}, {name}, {company}, {title}.
Write "Hi {firstName}," — never invent a bracketed placeholder such as [Name] or [Company],
never address the recipient by their job title, and never put a real person's name in the text.
A token whose field may be missing needs a fallback after a pipe, e.g. {company|your team},
otherwise the sentence loses a word for recipients without that field.

Return ONLY the message body: no subject line, no "Subject:" header, no explanations, no
markdown and no surrounding quotes. The subject is a separate field and must not appear in
the body.
Keep the core message but optimize for the platform's style and constraints.
"""
        
        return callGeminiApi(ec, prompt, [temperature: 0.6, maxOutputTokens: 1024, ownerPartyId: ownerPartyId])
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
     * @param ownerPartyId Optional tenant id, used to resolve SystemSettings.aiModelName
     * @return The polished message
     */
    static String polishMessage(def ec, String draftMessage, String platform,
            String recipientName = null, String recipientCompany = null, String recipientTitle = null,
            String ownerPartyId = null) {
        def prompt = """
Improve the tone and flow of the following already-personalized ${platform} outreach message.
Keep it roughly the same length and keep all specific facts (names, companies, titles) intact.
Do not add claims that aren't already present. Do not add a greeting/sign-off if the draft doesn't have one.

RECIPIENT: ${recipientName ?: '(unknown)'}${recipientTitle ? ' - ' + recipientTitle : ''}${recipientCompany ? ' at ' + recipientCompany : ''}

DRAFT MESSAGE:
${draftMessage}

Return ONLY the revised message body, no explanations, no markdown and no "Subject:" line:
the subject is a separate field and must not appear in the body.
"""

        return callGeminiApi(ec, prompt, [temperature: 0.5, maxOutputTokens: 1024, ownerPartyId: ownerPartyId])
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
                return "- Professional tone\n- Clear call-to-action\n- Open with \"Hi {firstName},\" and close with a one-line sign-off\n- Body text only, the subject is set separately\n- Keep concise but complete"
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
     * @param ownerPartyId Optional tenant id, used to resolve SystemSettings.aiModelName
     * @return The adapted, ready-to-publish text for that platform
     */
    static String generateAdaptedContent(def ec, String title, String body, String platform,
            String contentType, String callToAction = null, String targetUrl = null,
            String ownerPartyId = null) {
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
        return callGeminiApi(ec, prompt, [temperature: 0.7, maxOutputTokens: 4096, ownerPartyId: ownerPartyId])
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
