import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import org.moqui.context.ExecutionContext
import java.net.HttpURLConnection
import java.net.URL

// Get ExecutionContext from context - it's directly available in Moqui service scripts
ExecutionContext ec = context.ec ?: context

try {
    // Get the Gemini API key from user preferences or environment variables
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        apiKey = System.getenv("GEMINI_API_KEY")
    }
    if (apiKey == null || apiKey.isEmpty()) {
        ec.message.addError("Gemini API key not found in user preferences (GEMINI_API_KEY) or environment variables.")
        return
    }
    
    ec.logger.info("Using Gemini API with key length: ${apiKey?.length()}")
    
    // Get the model from parameters or use a default
    def modelName = ec.context.model ?: "gemini-2.5-pro"
    
    ec.logger.info("Using model: ${modelName}")
    
    // Build the API endpoint URL - Use the correct Gemini API endpoint
    // The generativelanguage.googleapis.com API DOES support API keys when using the correct format
    // The key must be in the URL as a query parameter
    def apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}"
    
    ec.logger.info("Full API URL: ${apiUrl.replaceAll(/(key=)[^&]*/, '$1***REDACTED***')}")
    ec.logger.info("Calling Gemini API endpoint for model: ${modelName}")
    
    // Prepare the request body
    def requestBody = [
        contents: [
            [
                parts: [
                    [text: prompt],
                    [
                        inline_data: [
                            mime_type: mimeType,
                            data: imageData
                        ]
                    ]
                ]
            ]
        ]
    ]
    
    // Make HTTP POST request
    URL url = new URL(apiUrl)
    HttpURLConnection conn = (HttpURLConnection) url.openConnection()
    conn.setRequestMethod("POST")
    conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
    conn.setRequestProperty("Accept", "application/json")
    conn.setDoOutput(true)
    conn.setDoInput(true)
    
    // Send request
    def jsonRequest = JsonOutput.toJson(requestBody)
    conn.outputStream.withWriter { writer ->
        writer.write(jsonRequest)
    }
    
    // Read response
    def responseCode = conn.responseCode
    ec.logger.info("Response code: ${responseCode}")
    
    if (responseCode == 200) {
        def responseText = conn.inputStream.text
        ec.logger.info("Success response received")
        def jsonSlurper = new JsonSlurper()
        def response = jsonSlurper.parseText(responseText)
        
        // Extract the text from the response
        def generatedText = response.candidates[0].content.parts[0].text
        
        // Clean up JSON markdown if present
        def cleanedJson = generatedText.replaceAll("```json", "").replaceAll("```", "").trim()
        
        // Parse the cleaned JSON string into a Map
        def resultMap = jsonSlurper.parseText(cleanedJson)
        
        // Set output parameters
        context.put("extractedData", resultMap)
        context.put("resultMap", resultMap)
        context.put("stringResult", cleanedJson)
    } else {
        def errorText = conn.errorStream?.text ?: "Unknown error"
        ec.logger.error("Gemini API error (${responseCode}): ${errorText}")
        ec.message.addError("Failed to process image (${responseCode}): ${errorText}")
    }
    
    conn.disconnect()
    
} catch (Exception e) {
    ec.logger.error("An error occurred while processing the invoice image", e)
    ec.message.addError("An error occurred while processing the invoice image: " + e.getMessage())
}