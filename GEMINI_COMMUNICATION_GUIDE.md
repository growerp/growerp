# Gemini Communication Guide

## Overview
GrowERP integrates with Google's Gemini AI model to extract structured data from invoice images. This document explains the communication flow, architecture, and integration points.

## Communication Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Frontend (Flutter)                               │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ InvoiceUploadView                                            │  │
│  │  - User selects invoice image via file picker               │  │
│  │  - Displays image preview                                   │  │
│  │  - User clicks "Upload and Process"                         │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
│                 │                                                   │
│  ┌──────────────▼───────────────────────────────────────────────┐  │
│  │ InvoiceUploadBloc                                            │  │
│  │  - Manages UI state (loading, success, failure)             │  │
│  │  - Converts image to base64                                 │  │
│  │  - Constructs REST API call                                 │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
└─────────────────┼──────────────────────────────────────────────────┘
                  │ REST API Call
                  │ POST /rest/s1/mcp/processInvoiceImage
                  │
┌─────────────────▼──────────────────────────────────────────────────┐
│                    Backend (Moqui)                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ McpServices.xml                                              │  │
│  │  - Defines "processInvoiceImage" service                    │  │
│  │  - Takes imageData, prompt, mimeType as input              │  │
│  │  - Returns extractedData (Map)                              │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
│                 │                                                   │
│  ┌──────────────▼───────────────────────────────────────────────┐  │
│  │ processInvoiceImage.groovy                                   │  │
│  │  - Retrieves Gemini API key from:                           │  │
│  │    * User preferences (GEMINI_API_KEY)                      │  │
│  │    * Environment variables (GEMINI_API_KEY)                 │  │
│  │  - Constructs Gemini API request:                           │  │
│  │    * Model: gemini-2.5-pro (configurable)                   │  │
│  │    * Endpoint: generativelanguage.googleapis.com/v1beta/... │  │
│  │    * Includes prompt + base64-encoded image                 │  │
│  │  - Handles HTTP POST request/response                       │  │
│  │  - Parses JSON response from Gemini                         │  │
│  │  - Cleans up markdown formatting (```json...)               │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
└─────────────────┼──────────────────────────────────────────────────┘
                  │ HTTPS API Call
                  │ POST generativelanguage.googleapis.com/v1beta/models/...
                  │
┌─────────────────▼──────────────────────────────────────────────────┐
│              Google Gemini API (Cloud)                              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Request Body:                                                │  │
│  │ {                                                            │  │
│  │   "contents": [                                             │  │
│  │     {                                                        │  │
│  │       "parts": [                                            │  │
│  │         { "text": "Extract invoice data..." },             │  │
│  │         {                                                   │  │
│  │           "inline_data": {                                 │  │
│  │             "mime_type": "image/jpeg",                     │  │
│  │             "data": "<base64-encoded-image>"               │  │
│  │           }                                                 │  │
│  │         }                                                   │  │
│  │       ]                                                     │  │
│  │     }                                                       │  │
│  │   ]                                                         │  │
│  │ }                                                            │  │
│  │                                                              │  │
│  │ Response:                                                    │  │
│  │ {                                                            │  │
│  │   "candidates": [{                                          │  │
│  │     "content": {                                            │  │
│  │       "parts": [{                                           │  │
│  │         "text": "```json\n{...invoice data...}\n```"       │  │
│  │       }]                                                    │  │
│  │     }                                                        │  │
│  │   }]                                                         │  │
│  │ }                                                            │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
└─────────────────┼──────────────────────────────────────────────────┘
                  │ Response: Extracted JSON
                  │
┌─────────────────▼──────────────────────────────────────────────────┐
│              Backend Response Processing                            │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ processInvoiceImage.groovy                                   │  │
│  │  - Extracts text from response                              │  │
│  │  - Removes markdown formatting (```json...)                 │  │
│  │  - Parses JSON into Map                                      │  │
│  │  - Sets context variables:                                  │  │
│  │    * extractedData: Final Map object                        │  │
│  │    * stringResult: JSON string                              │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
└─────────────────┼──────────────────────────────────────────────────┘
                  │ REST Response
                  │ { extractedData: { supplier: "...", items: [...] } }
                  │
┌─────────────────▼──────────────────────────────────────────────────┐
│                    Frontend (Flutter)                               │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ InvoiceUploadBloc                                            │  │
│  │  - Receives extractedData                                    │  │
│  │  - Updates state to success/failure                         │  │
│  │  - Stores extracted data in state                           │  │
│  └──────────────┬───────────────────────────────────────────────┘  │
│                 │                                                   │
│  ┌──────────────▼───────────────────────────────────────────────┐  │
│  │ InvoiceUploadView                                            │  │
│  │  - Displays extracted data in JSON format                   │  │
│  │  - Shows "Create Invoice" button                            │  │
│  │  - User reviews and confirms                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Communication Flow Steps

### 1. Frontend Preparation
- User selects invoice image via device file picker
- Image is converted to base64 encoding
- Frontend sends REST API request with:
  - `imageData`: Base64-encoded image
  - `prompt`: Instructions for Gemini (e.g., "Extract invoice data...")
  - `mimeType`: "image/jpeg" (configurable)

### 2. Backend Receipt
- REST endpoint `/rest/s1/mcp/processInvoiceImage` receives request
- Groovy service `processInvoiceImage.groovy` is executed

### 3. API Key Retrieval
The backend looks for Gemini API key in this order:
1. User preferences table (key: `GEMINI_API_KEY`)
2. System environment variables (`GEMINI_API_KEY`)

If not found, error message is returned to frontend.

### 4. Gemini API Request
- Constructs HTTPS request to: `https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent`
- Model used: `gemini-2.5-pro` (can be configured via context parameter)
- API key passed as URL query parameter: `?key={API_KEY}`
- Request body contains:
  - Prompt text (extraction instructions)
  - Base64-encoded image with MIME type
- All sent with `Content-Type: application/json`

### 5. Gemini Processing
- Google Gemini API processes image and prompt
- Generates JSON response with extracted invoice data
- Response includes:
  - Supplier/vendor name
  - Invoice date
  - Line items (description, quantity, price)
  - Total amount (if detected)

### 6. Backend Response Parsing
- Extracts text from response (nested in `candidates[0].content.parts[0].text`)
- Removes markdown formatting (strips ````json` and ````` delimiters)
- Parses cleaned JSON string into Map object
- Sets output parameters in Moqui context:
  - `extractedData`: The parsed Map
  - `stringResult`: The JSON string
  - `resultMap`: Copy of parsed Map

### 7. Frontend Result Display
- Receives extractedData from API response
- InvoiceUploadBloc updates state to success
- InvoiceUploadView displays extracted data
- User can review and confirm, or cancel

### 8. Invoice Creation (Optional)
- If user approves, extracted data is used to:
  - Find or create supplier company
  - Find or create products
  - Create FinDoc (invoice) record
- Success confirmation shown to user

## Key Files

| File | Purpose | Type |
|------|---------|------|
| `/moqui/runtime/component/mcp/service/processInvoiceImage.groovy` | Main Gemini communication logic | Backend |
| `/moqui/runtime/component/mcp/service/McpServices.xml` | Service definition | Backend |
| `InvoiceUploadBloc` | State management for invoice upload | Frontend |
| `InvoiceUploadView` | User interface for image selection | Frontend |
| `.gemini/get_api_key.sh` | Script to retrieve API key from server | DevOps |
| `gemini-wrapper.sh` | CLI wrapper for Gemini with memory optimization | DevOps |

## API Key Management

### Getting an API Key

1. **From User Preferences (within GrowERP)**:
   - User stores their Gemini API key in user preferences
   - Stored with key: `GEMINI_API_KEY`

2. **From Environment Variable**:
   - Set environment variable: `GEMINI_API_KEY=your-key-here`
   - Useful for server deployments

3. **Using the Setup Script**:
   ```bash
   ./get_api_key.sh [username] [password] [classificationId] --update
   ```
   - Gets fresh API key via login
   - Optionally updates `.gemini/settings.json`

### MCP Server Integration
- GrowERP provides an MCP (Model Context Protocol) server endpoint
- Gemini CLI can connect to `/rest/s1/mcp/protocol` endpoint
- Requires API key from header for authentication

## Configuration

### Model Selection
Backend uses `gemini-2.5-pro` by default, but can be overridden:
```groovy
def modelName = ec.context.model ?: "gemini-2.5-pro"
```

### Image Format
Default MIME type is `image/jpeg`, can be configured per request

### Prompt Customization
The extraction prompt can be customized based on invoice format or requirements

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Gemini API key not found` | API key missing from preferences and env vars | Set `GEMINI_API_KEY` in preferences or environment |
| `HTTP 401/403` | Invalid or expired API key | Generate new API key from Google Cloud |
| `HTTP 400` | Malformed request to Gemini API | Check image encoding, MIME type, and prompt format |
| `Response parsing failed` | Gemini response format unexpected | Check model version compatibility |

### Logging
- Gemini API URL (with key redacted) is logged
- Response codes are logged
- Detailed error messages from Gemini are captured

## Security Considerations

1. **API Key Protection**:
   - Never log the full API key (redacted in logs)
   - Store in environment variables or user preferences, not in code
   - Use HTTPS for all communication with Gemini

2. **Image Handling**:
   - Images are base64-encoded before transmission
   - No image is stored on server after processing
   - Images are only used for extraction, not training

3. **Data Extraction**:
   - Only invoice data is extracted
   - Response is parsed and converted to structured JSON
   - No personally identifiable information is retained

## Testing

### Manual Testing
1. Access GrowERP application
2. Navigate to Invoice Upload
3. Select test invoice image
4. Click "Upload and Process"
5. Verify extracted data appears
6. Review data accuracy
7. Create invoice to confirm integration

### Test Images
Use sample invoice images with clear structure and typical invoice formatting

### Debug Logging
Enable debug logging in Moqui to see:
- API URL construction
- Request payload (without key)
- Response codes
- Parsed JSON output

## Integration with MCP Clients

GrowERP's MCP server can be accessed via:
- **Gemini CLI**: Uses `/rest/s1/mcp/protocol` endpoint
- **Claude Desktop**: Compatible with same endpoint
- **Custom MCP Clients**: Standard JSON-RPC 2.0 protocol

### Connecting Gemini CLI

1. Update `.gemini/settings.json` with API key
2. Run: `gemini-wrapper.sh [command]` or `gemini [command]`
3. MCP client connects to GrowERP backend automatically

## Performance Optimization

### Memory Management (CLI)
The `gemini-wrapper.sh` script optimizes memory usage:
```bash
export NODE_OPTIONS="--max-old-space-size=8192"
```
- Sets 8GB max memory for Node.js
- Enables garbage collection optimizations
- Disables memory pressure warnings

### Backend Optimization
- Image data is not stored on disk
- Response is processed in-memory
- Connection is closed immediately after response

## Future Enhancements

1. **Multi-Model Support**: Support for different Gemini models
2. **Batch Processing**: Process multiple invoices at once
3. **Custom Extraction Rules**: Allow configuration of what data to extract
4. **OCR Fallback**: Use OCR if Gemini extraction fails
5. **Invoice History**: Track extraction accuracy over time
6. **User Feedback**: Allow users to correct extraction and improve model training

## References

- [Gemini API Documentation](https://ai.google.dev/gemini-api)
- [Invoice Scan Documentation](./Invoice_Scan_Documentation.md)
- [MCP Protocol Specification](./moqui/runtime/component/mcp/docs/)
- [GrowERP Backend Integration](./docs/)
