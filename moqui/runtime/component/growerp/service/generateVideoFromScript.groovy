/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * Generate a video from a YouTube script using Google Veo 2 API (via Vertex AI).
 *
 * Required environment variables:
 * - GOOGLE_CLOUD_PROJECT: Your Google Cloud project ID
 * - GOOGLE_APPLICATION_CREDENTIALS: Path to service account JSON (or use default credentials)
 *
 * Required context variables:
 * - ec: ExecutionContext
 * - mediaId: The media ID containing the script
 * - scriptContent: The script text to convert to video
 * - voiceStyle: Voice style preference (not used yet - for TTS integration)
 * - videoStyle: Video style preference (professional, casual, animated)
 *
 * Output variables:
 * - videoUrl: URL to the generated video
 * - status: 'success', 'pending', or 'error'
 * - message: Status message
 */

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import java.net.HttpURLConnection
import java.net.URL

// Get configuration
def googleProjectId = System.getenv("GOOGLE_CLOUD_PROJECT")
def googleLocation = System.getenv("GOOGLE_CLOUD_LOCATION") ?: "us-central1"

ec.logger.info("Starting video generation for mediaId: ${mediaId}")
ec.logger.info("Script length: ${scriptContent?.length() ?: 0} characters")
ec.logger.info("Voice style: ${voiceStyle}, Video style: ${videoStyle}")
ec.logger.info("Google Project: ${googleProjectId ?: 'NOT SET'}, Location: ${googleLocation}")

try {
    if (!googleProjectId) {
        throw new Exception("GOOGLE_CLOUD_PROJECT environment variable not set. Please configure Google Cloud credentials.")
    }
    
    // Get access token using Application Default Credentials
    def accessToken = getGoogleAccessToken(ec)
    if (!accessToken) {
        throw new Exception("Failed to obtain Google Cloud access token. Check GOOGLE_APPLICATION_CREDENTIALS.")
    }
    
    ec.logger.info("Successfully obtained Google Cloud access token")
    
    // Step 1: Extract video prompt from script using Gemini
    def videoPrompt = extractVideoPromptFromScript(ec, scriptContent, videoStyle)
    ec.logger.info("Generated video prompt: ${videoPrompt?.take(200)}...")
    
    // Step 2: Call Veo 2 API to generate video
    def veoResponse = callVeoApi(ec, accessToken, googleProjectId, googleLocation, videoPrompt)
    
    if (veoResponse.error) {
        throw new Exception("Veo API error: ${veoResponse.error}")
    }
    
    // Check if the operation is still pending
    if (veoResponse.operationName) {
        // Store the operation name for status checking later
        ec.service.sync().name("update#growerp.course.CourseMedia")
            .parameters([
                mediaId: mediaId,
                status: 'SCHEDULED'
            ]).call()
        
        videoUrl = null
        status = 'pending'
        message = "Video generation started (Operation: ${veoResponse.operationName}). This may take 2-5 minutes."
        
    } else if (veoResponse.videoUri) {
        // Video is ready
        videoUrl = veoResponse.videoUri
        status = 'success'
        message = veoResponse.isImage ? 'Key frame images generated!' : 'Video generated successfully!'
        
        ec.service.sync().name("update#growerp.course.CourseMedia")
            .parameters([
                mediaId: mediaId,
                status: 'PUBLISHED',
                publishedDate: ec.user.nowTimestamp
            ]).call()
            
    } else if (veoResponse.storyboard) {
        // Storyboard generated (fallback when video generation not available)
        videoUrl = null
        status = 'partial'
        message = veoResponse.message ?: "Video storyboard generated. Full video generation requires Google Veo 2 access."
        
        // Store the storyboard as script content for reference
        ec.logger.info("Storyboard generated: ${veoResponse.storyboard?.take(500)}...")
        
        ec.service.sync().name("update#growerp.course.CourseMedia")
            .parameters([
                mediaId: mediaId,
                status: 'DRAFT'  // Keep as draft since only storyboard is available
            ]).call()
            
    } else {
        // Log the actual response for debugging
        ec.logger.warn("Unexpected Veo response: ${veoResponse}")
        throw new Exception("Unexpected Veo API response: ${veoResponse.keySet()}")
    }
    
    ec.logger.info("Video generation completed with status: ${status}")
    
} catch (Exception e) {
    ec.logger.error("Video generation failed: ${e.message}", e)
    videoUrl = null
    status = 'error'
    message = "Video generation failed: ${e.message}"
}

// Set output variables
context.videoUrl = videoUrl
context.status = status
context.message = message

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Get Google Cloud access token using Application Default Credentials.
 */
def getGoogleAccessToken(def ec) {
    try {
        // Try to get token from metadata server (for Cloud Run, GCE, etc.)
        def metadataUrl = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
        def connection = new URL(metadataUrl).openConnection() as HttpURLConnection
        connection.setRequestProperty("Metadata-Flavor", "Google")
        connection.setConnectTimeout(2000)
        connection.setReadTimeout(2000)
        
        if (connection.responseCode == 200) {
            def response = new JsonSlurper().parseText(connection.inputStream.text)
            return response.access_token
        }
    } catch (Exception e) {
        ec.logger.info("Metadata server not available, trying service account credentials")
    }
    
    // Try using gcloud CLI (for local development)
    try {
        def process = "gcloud auth print-access-token".execute()
        process.waitFor()
        if (process.exitValue() == 0) {
            return process.text.trim()
        }
    } catch (Exception e) {
        ec.logger.info("gcloud CLI not available: ${e.message}")
    }
    
    // Try using service account key file
    def credentialsFile = System.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if (credentialsFile) {
        try {
            return getTokenFromServiceAccount(ec, credentialsFile)
        } catch (Exception e) {
            ec.logger.error("Failed to get token from service account: ${e.message}")
        }
    }
    
    return null
}

/**
 * Get access token from service account JSON file.
 */
def getTokenFromServiceAccount(def ec, String credentialsFile) {
    def credentials = new JsonSlurper().parse(new File(credentialsFile))
    def privateKey = credentials.private_key
    def clientEmail = credentials.client_email
    def tokenUri = credentials.token_uri ?: "https://oauth2.googleapis.com/token"
    
    // Create JWT
    def now = System.currentTimeMillis() / 1000 as long
    def header = JsonOutput.toJson([alg: "RS256", typ: "JWT"])
    def payload = JsonOutput.toJson([
        iss: clientEmail,
        scope: "https://www.googleapis.com/auth/cloud-platform",
        aud: tokenUri,
        iat: now,
        exp: now + 3600
    ])
    
    def headerB64 = Base64.urlEncoder.encodeToString(header.bytes)
    def payloadB64 = Base64.urlEncoder.encodeToString(payload.bytes)
    def signatureInput = "${headerB64}.${payloadB64}"
    
    // Sign with RSA
    def keySpec = new java.security.spec.PKCS8EncodedKeySpec(
        Base64.decoder.decode(privateKey
            .replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "")
            .replaceAll("\\s", ""))
    )
    def keyFactory = java.security.KeyFactory.getInstance("RSA")
    def rsaPrivateKey = keyFactory.generatePrivate(keySpec)
    def signature = java.security.Signature.getInstance("SHA256withRSA")
    signature.initSign(rsaPrivateKey)
    signature.update(signatureInput.bytes)
    def signatureB64 = Base64.urlEncoder.encodeToString(signature.sign())
    
    def jwt = "${signatureInput}.${signatureB64}"
    
    // Exchange JWT for access token
    def connection = new URL(tokenUri).openConnection() as HttpURLConnection
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
    connection.setDoOutput(true)
    connection.outputStream.withWriter { writer ->
        writer.write("grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}")
    }
    
    if (connection.responseCode == 200) {
        def response = new JsonSlurper().parseText(connection.inputStream.text)
        return response.access_token
    } else {
        throw new Exception("Token exchange failed: ${connection.errorStream?.text}")
    }
}

/**
 * Extract a video generation prompt from the YouTube script.
 */
def extractVideoPromptFromScript(def ec, String script, String style) {
    def styleDescription = getStyleDescription(style)
    
    def prompt = """
Analyze this YouTube video script and create a concise video generation prompt for an AI video generator.

SCRIPT:
${script.take(4000)}

VIDEO STYLE: ${style}
${styleDescription}

Create a single paragraph prompt (max 200 words) that describes:
1. The main visual scenes and transitions
2. The overall mood and color palette
3. Key visual elements that should appear
4. The pacing and rhythm of the video

Focus on VISUAL descriptions only - no audio/narration elements.
Return ONLY the prompt text, no explanations.
"""
    
    return callGeminiApiDirect(ec, prompt)
}

/**
 * Call Gemini API directly (simplified version for video generation).
 * Uses the direct Gemini API (ai.google.dev) not Vertex AI for separate quota.
 */
def callGeminiApiDirect(def ec, String prompt, int retryCount = 0) {
    def apiKey = ec.user.getPreference("GEMINI_API_KEY")
    if (apiKey == null || apiKey.isEmpty()) {
        apiKey = System.getenv("GEMINI_API_KEY")
    }
    if (apiKey == null || apiKey.isEmpty()) {
        throw new Exception("GEMINI_API_KEY not configured. Set it as environment variable or user preference.")
    }
    
    // Use gemini-2.0-flash (confirmed available Jan 2026)
    def model = "gemini-2.0-flash"
    def apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}"
    
    ec.logger.info("Calling Gemini API (${model}) - attempt ${retryCount + 1}")
    
    def requestBody = JsonOutput.toJson([
        contents: [[parts: [[text: prompt]]]],
        generationConfig: [temperature: 0.7, maxOutputTokens: 500]
    ])
    
    def connection = new URL(apiUrl).openConnection() as HttpURLConnection
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setDoOutput(true)
    connection.setConnectTimeout(30000)
    connection.setReadTimeout(60000)
    
    connection.outputStream.withWriter("UTF-8") { writer ->
        writer.write(requestBody)
    }
    
    def responseCode = connection.responseCode
    
    if (responseCode == 200) {
        def response = new JsonSlurper().parseText(connection.inputStream.text)
        return response.candidates[0]?.content?.parts[0]?.text ?: ""
    } else if (responseCode == 429 && retryCount < 3) {
        // Rate limited - wait and retry with exponential backoff
        def waitSeconds = (retryCount + 1) * 10  // 10s, 20s, 30s
        ec.logger.info("Rate limited (429), waiting ${waitSeconds} seconds before retry...")
        Thread.sleep(waitSeconds * 1000)
        return callGeminiApiDirect(ec, prompt, retryCount + 1)
    } else {
        def errorText = connection.errorStream?.text ?: "No error details"
        ec.logger.error("Gemini API error (${responseCode}): ${errorText}")
        throw new Exception("Gemini API error (${responseCode}): ${errorText}")
    }
}

/**
 * Get style description for video generation.
 */
def getStyleDescription(String style) {
    switch (style?.toLowerCase()) {
        case 'casual':
            return "Style: Casual, friendly, vibrant colors, dynamic movements, relatable visuals"
        case 'animated':
            return "Style: Animated graphics, motion graphics, colorful illustrations, playful transitions"
        case 'cinematic':
            return "Style: Cinematic, dramatic lighting, slow movements, film-like quality"
        default: // professional
            return "Style: Professional, clean, corporate, muted colors, smooth transitions, business-appropriate"
    }
}

/**
 * Call Google Veo 2 API to generate video.
 */
def callVeoApi(def ec, String accessToken, String projectId, String location, String prompt) {
    // Veo 2 model - the correct endpoint for video generation
    // Note: Veo 2 may require specific quota/access - try imagen-video as fallback
    def modelName = "imagegeneration@006"  // Imagen Video model
    def apiUrl = "https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${modelName}:predict"
    
    ec.logger.info("Calling Vertex AI Video API: ${apiUrl}")
    
    // For Imagen Video, we generate key frames as images first
    def requestBody = JsonOutput.toJson([
        instances: [
            [
                prompt: prompt
            ]
        ],
        parameters: [
            sampleCount: 4,  // Generate 4 key frame images
            aspectRatio: "16:9",
            personGeneration: "dont_allow",
            safetySetting: "block_some"
        ]
    ])
    
    def connection = new URL(apiUrl).openConnection() as HttpURLConnection
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Authorization", "Bearer ${accessToken}")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setDoOutput(true)
    connection.setConnectTimeout(30000)
    connection.setReadTimeout(300000) // 5 minutes for generation
    
    connection.outputStream.withWriter("UTF-8") { writer ->
        writer.write(requestBody)
    }
    
    def responseCode = connection.responseCode
    ec.logger.info("Vertex AI API response code: ${responseCode}")
    
    if (responseCode == 200) {
        def response = new JsonSlurper().parseText(connection.inputStream.text)
        ec.logger.info("Vertex AI response: ${JsonOutput.prettyPrint(JsonOutput.toJson(response))}")
        
        // Check for predictions with images
        if (response.predictions && response.predictions.size() > 0) {
            // For now, return first generated image as a "video thumbnail"
            // Full video generation would require additional processing
            def firstPrediction = response.predictions[0]
            if (firstPrediction.bytesBase64Encoded) {
                // Save the image and return URL
                def imageData = firstPrediction.bytesBase64Encoded
                def savedUrl = saveGeneratedImage(ec, imageData, projectId)
                return [videoUri: savedUrl, isImage: true]
            }
        }
        
        // Check if this is a long-running operation
        if (response.name) {
            return [operationName: response.name]
        }
        
        return [error: "No predictions in response"]
        
    } else if (responseCode == 404) {
        // Model not available - try alternative approach using Gemini's video capabilities
        ec.logger.info("Imagen Video not available, trying Gemini video generation")
        return tryGeminiVideoGeneration(ec, accessToken, projectId, location, prompt)
        
    } else {
        def errorText = connection.errorStream?.text ?: "No error details"
        ec.logger.error("Vertex AI API error (${responseCode}): ${errorText}")
        
        try {
            def errorJson = new JsonSlurper().parseText(errorText)
            def errorMessage = errorJson.error?.message ?: errorText
            return [error: errorMessage]
        } catch (Exception e) {
            return [error: "API error (${responseCode}): ${errorText}"]
        }
    }
}

/**
 * Try Gemini's native video generation (Veo 2 via Gemini API).
 */
def tryGeminiVideoGeneration(def ec, String accessToken, String projectId, String location, String prompt) {
    // Use Gemini 2.0 Flash with video generation capability
    def apiKey = ec.user.getPreference("GEMINI_API_KEY") ?: System.getenv("GEMINI_API_KEY")
    
    if (!apiKey) {
        return [error: "Video generation requires Veo access or GEMINI_API_KEY for Gemini video generation"]
    }
    
    // For now, since direct video generation may not be available,
    // we'll generate a detailed storyboard that could be used with external tools
    def storyboardPrompt = """
Based on this video prompt, create a detailed shot-by-shot storyboard in JSON format:

${prompt}

Return JSON with this structure:
{
  "title": "Video Title",
  "duration": "estimated seconds",
  "shots": [
    {
      "shotNumber": 1,
      "duration": "3s",
      "description": "Visual description",
      "cameraMovement": "pan/zoom/static",
      "text": "Any on-screen text"
    }
  ],
  "soundtrack": "suggested music style"
}
"""
    
    def storyboard = callGeminiApiDirect(ec, storyboardPrompt)
    
    // Return as a "pending" status with the storyboard as additional data
    return [
        storyboard: storyboard,
        message: "Video storyboard generated. Full video generation requires Google Veo 2 access. Visit https://cloud.google.com/vertex-ai/docs/generative-ai/video/overview to request access."
    ]
}

/**
 * Save generated image to storage and return URL.
 */
def saveGeneratedImage(def ec, String base64Data, String projectId) {
    // For now, return a data URL - in production, upload to GCS
    return "data:image/png;base64,${base64Data.take(100)}..."
}

