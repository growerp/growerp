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

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import org.moqui.context.ExecutionContext

// Get ExecutionContext
ExecutionContext ec = context.ec ?: context

// Only these platforms/actions are supported by the campaign detail screen,
// anything else is silently dropped when the campaign is opened for editing.
def supportedActions = [EMAIL: ['send_email'],
                        LINKEDIN: ['message_connections', 'search_and_connect']]

try {
    ec.logger.info("AI Campaign Generation requested for goal: ${campaignGoal}")

    // Step 1: Get owner party ID from authenticated user context
    def ownerResult = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
        .call()
    def ownerPartyId = ownerResult.ownerPartyId

    if (!ownerPartyId) {
        ec.message.addError("Unable to determine owner party ID from authenticated user")
        return
    }

    // Step 2: Determine the platforms to generate for
    def selectedPlatforms = (platforms ?: 'EMAIL,LINKEDIN').split(',')
        .collect { it.trim().toUpperCase() }
        .findAll { supportedActions.containsKey(it) }
    if (!selectedPlatforms) {
        ec.message.addError("No supported platform selected, use EMAIL and/or LINKEDIN")
        return
    }

    // Step 3: Load the shared LLM helper; it resolves provider, model and key per tenant
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

    // Step 4: Construct the prompt, listing the allowed action types per platform
    def platformRules = selectedPlatforms.collect {
        "- ${it.toLowerCase()}: actionType must be one of ${supportedActions[it].join(' or ')}"
    }.join('\n')

    def generationPrompt = """
Create an outreach campaign for the following goal:

CAMPAIGN GOAL:
${campaignGoal}

TARGET AUDIENCE: ${targetAudience ?: 'Not specified - infer from the campaign goal'}

PLATFORMS: ${selectedPlatforms.join(', ')}

REQUIREMENTS:
1. campaignName: short and recognisable (max 50 characters)
2. campaignSummary: 2-3 sentences describing what the campaign does and why
3. targetAudience: one string describing who is contacted
4. emailSubject: a subject line that gets opened (max 70 characters)
5. messageTemplate: the base outreach message (100-150 words). Personalize with
   the tokens \${firstName}, \${lastName} and \${companyName} where natural
6. platformSettings: one entry per platform, keys lowercase:
${platformRules}
   - messageTemplate: the message adapted to that platform (LinkedIn short and
     conversational, email longer and structured)
   - searchKeywords: only meaningful for the linkedin search_and_connect action,
     otherwise an empty string

RETURN FORMAT: Return ONLY valid JSON (no markdown, no code blocks) with this exact
structure. All values MUST be plain strings, never arrays or lists:
{
  "campaignName": "Campaign name",
  "campaignSummary": "What the campaign does and why",
  "targetAudience": "Who is contacted",
  "emailSubject": "Subject line",
  "messageTemplate": "Base outreach message",
  "platformSettings": {
${selectedPlatforms.collect { "    \"${it.toLowerCase()}\": {\"actionType\": \"${supportedActions[it][0]}\", \"searchKeywords\": \"\", \"messageTemplate\": \"...\"}" }.join(',\n')}
  }
}

Generate the campaign now.
"""

    ec.logger.info("Calling the configured LLM for campaign generation...")

    // Step 5: Call the tenant's LLM (gemini, anthropic or openai)
    def generatedText = GeminiAiUtil.callLlmApi(ec, generationPrompt,
        [ownerPartyId: ownerPartyId, temperature: 0.8, maxOutputTokens: 4096])
    ec.logger.info("Generated campaign text: ${generatedText}")

    // Clean up markdown code blocks if present
    generatedText = generatedText.replaceAll(/```json\s*/, '').replaceAll(/```\s*$/, '').trim()

    // Step 6: Parse the JSON response
    def campaignData = new JsonSlurper().parseText(generatedText)

    // Step 7: Keep only supported platforms/actions, fall back to the default
    // action when the model invented one we cannot execute
    def settings = [:]
    selectedPlatforms.each { platform ->
        def generated = campaignData.platformSettings?.get(platform.toLowerCase()) ?: [:]
        def actionType = generated.actionType
        if (!supportedActions[platform].contains(actionType)) {
            actionType = supportedActions[platform][0]
        }
        settings[platform.toLowerCase()] = [
            actionType: actionType,
            searchKeywords: generated.searchKeywords ?: '',
            messageTemplate: generated.messageTemplate ?: campaignData.messageTemplate ?: ''
        ]
    }

    // The frontend stores platforms as a Dart list toString: "[EMAIL, LINKEDIN]"
    def platformsString = "[${selectedPlatforms.join(', ')}]"

    // Step 8: Create through the regular service so pseudoId, status, the
    // automation job sync and the metrics record are all handled there
    def createResult = ec.service.sync().name("growerp.100.OutreachServices100.create#OutreachCampaign")
        .parameters([campaign: [
            campaignName: campaignData.campaignName,
            campaignSummary: campaignData.campaignSummary,
            platforms: platformsString,
            targetAudience: campaignData.targetAudience ?: targetAudience,
            messageTemplate: campaignData.messageTemplate,
            emailSubject: campaignData.emailSubject,
            platformSettings: JsonOutput.toJson(settings)
        ]])
        .call()
    if (ec.message.hasError()) return

    campaign = createResult.campaign
    ec.logger.info("Created campaign with AI: ${campaign?.marketingCampaignId}")
    ec.message.addMessage("Campaign generated with AI")
} catch (Exception e) {
    ec.logger.error("Campaign AI generation failed", e)
    ec.message.addError("Failed to generate campaign: ${e.message}")
}
