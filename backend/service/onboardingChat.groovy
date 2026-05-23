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

ExecutionContext ec = context.ec ?: context

try {
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (!apiKey) apiKey = System.getenv("GEMINI_API_KEY")
    if (!apiKey) {
        ec.message.addError("GEMINI_API_KEY not configured.")
        return
    }

    // Build proper Gemini multi-turn conversation contents.
    // messages format: [{role:"user"|"model", parts:[{text:"..."}]}]
    // Gemini requires alternating user/model turns starting with user.
    def contents = messages.collect { msg ->
        def role = msg.role == "model" ? "model" : "user"
        def text = msg.parts?.find { it.text }?.text ?: ""
        [role: role, parts: [[text: text]]]
    }

    // Ensure we have at least one user turn (safety guard)
    if (!contents) {
        contents = [[role: "user", parts: [[text: "Start onboarding."]]]]
    }

    def model = ec.user.getPreference("GEMINI_MODEL") ?: System.getenv("GEMINI_MODEL") ?: System.getProperty("GEMINI_MODEL") ?: "gemini-3.5-flash"
    def geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}"
    def connection = new URL(geminiUrl).openConnection() as HttpURLConnection
    connection.requestMethod = "POST"
    connection.setRequestProperty("Content-Type", "application/json")
    connection.doOutput = true

    def requestBody = JsonOutput.toJson([
        systemInstruction: [parts: [[text: systemPrompt]]],
        contents: contents,
        generationConfig: [maxOutputTokens: 2048]
    ])

    connection.outputStream.withWriter("UTF-8") { it.write(requestBody) }

    def responseCode = connection.responseCode
    def responseText = responseCode == 200
        ? connection.inputStream.text
        : connection.errorStream?.text ?: "HTTP ${responseCode}"

    if (responseCode != 200) {
        ec.message.addError("Gemini API error ${responseCode}: ${responseText}")
        return
    }

    def parsed = new JsonSlurper().parseText(responseText)
    jsonl = parsed.candidates?[0]?.content?.parts?[0]?.text ?: ""

} catch (Exception e) {
    ec.message.addError("Onboarding chat error: ${e.message}")
}
