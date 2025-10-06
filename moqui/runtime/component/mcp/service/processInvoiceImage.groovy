import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import java.nio.charset.StandardCharsets
import org.moqui.context.ExecutionContext

def ec = context.getExecutionContext()

try {
    // Get the Gemini API key from environment variables
    def apiKey = System.getenv("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        ec.getMessage().addError("Gemini API key not found in environment variables.")
        return
    }

    // Prepare the request for the Gemini API
    def apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=" + apiKey
    def requestBody = [
        "contents": [
            [
                "parts": [
                    ["text": prompt],
                    [
                        "inline_data": [
                            "mime_type": mimeType,
                            "data": imageData
                        ]
                    ]
                ]
            ]
        ]
    ]

    def jsonBody = JsonOutput.toJson(requestBody)

    // Make the POST request to the Gemini API
    def url = new URL(apiUrl)
    def connection = (HttpURLConnection) url.openConnection()
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setDoOutput(true)

    def writer = new OutputStreamWriter(connection.getOutputStream(), StandardCharsets.UTF_8)
    writer.write(jsonBody)
    writer.flush()
    writer.close()

    // Read the response
    def responseCode = connection.getResponseCode()
    if (responseCode == HttpURLConnection.HTTP_OK) {
        def responseStream = connection.getInputStream()
        def responseText = responseStream.getText(StandardCharsets.UTF_8.toString())
        responseStream.close()

        def jsonSlurper = new JsonSlurper()
        def responseObject = jsonSlurper.parseText(responseText)

        // Extract the text content from the response
        def extractedText = responseObject.candidates[0].content.parts[0].text

        // The response from Gemini might be in a markdown format, so we need to clean it up
        def cleanedJson = extractedText.replaceAll("```json", "").replaceAll("```", "").trim()

        context.put("stringResult", cleanedJson)
    } else {
        ec.getMessage().addError("Error calling Gemini API: " + responseCode + " " + connection.getResponseMessage())
    }
} catch (Exception e) {
    ec.getMessage().addError("An error occurred while processing the invoice image: " + e.getMessage())
}