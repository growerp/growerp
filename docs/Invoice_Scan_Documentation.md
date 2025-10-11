# Invoice Scan Documentation

## Overview

The Invoice Scan feature in GrowERP allows users to upload invoice images and automatically extract structured data using AI/ML processing. This functionality streamlines the invoice data entry process by converting physical or digital invoice images into structured JSON data that can be used to create invoices in the system.

## Architecture

### Components

1. **InvoiceUploadView** - The main UI component for invoice scanning
2. **InvoiceUploadBloc** - Business logic layer handling state management
3. **Image Processing Service** - Backend service for AI-powered data extraction

### File Structure

```
growerp_order_accounting/
├── lib/src/findoc/
│   ├── views/
│   │   └── invoice_upload_view.dart
│   └── blocs/
│       └── invoice_upload/
│           └── invoice_upload_bloc.dart
```

## User Workflow

### Step 1: Image Selection
- User opens the Invoice Upload dialog
- User can select an image from their device gallery using the "Pick Image" button
- Supported formats: JPEG images
- Selected image is displayed in a preview container (200px height)

### Step 2: Image Processing
- User clicks "Upload and Process" button to send the image for AI processing
- The system sends the image along with a structured prompt to extract invoice data
- Loading indicator is displayed during processing

### Step 3: Data Review
- Extracted data is displayed in JSON format for user review
- Data includes:
  - **Supplier information**
  - **Invoice date**
  - **Line items** with:
    - Description
    - Quantity
    - Unit price

### Step 4: Invoice Creation
- User can create an invoice from the extracted data
- System automatically finds or creates supplier companies
- System automatically finds or creates products for each line item
- Invoice is created using GrowERP's FinDoc system with proper product references
- Success message confirms invoice creation
- Dialog closes automatically upon successful creation

## Technical Implementation

### UI Components

#### Main Dialog
```dart
Dialog(
  key: Key('InvoiceUploadDialog'),
  title: "Upload Invoice",
  height: 600,
  width: 500
)
```

#### Key Interactive Elements
- **Pick Image Button** (`Key: 'pickImage'`)
- **Process Image Button** (`Key: 'processImage'`)
- **Create Invoice Button** (`Key: 'createInvoice'`)

### State Management

The feature uses BLoC pattern with the following states:

#### InvoiceUploadStatus
- `initial` - Default state
- `loading` - Processing image or creating invoice
- `success` - Operation completed successfully
- `failure` - Error occurred during processing

#### State Properties
- `extractedData` - JSON object containing parsed invoice data
- `invoice` - Created invoice object
- `message` - Status or error messages

### Events

#### InvoiceUploadImage
Triggers AI processing of the uploaded image:
```dart
InvoiceUploadImage(
  image: XFile,
  prompt: String,
  mimeType: 'image/jpeg'
)
```

#### InvoiceCreate
Creates an invoice from extracted data:
```dart
InvoiceCreate(Map<String, dynamic> extractedData)
```

## Data Extraction

### AI Prompt
The system uses a structured prompt to guide the AI extraction:

```
"Extract invoice data as a JSON object with fields: 
'supplier', 'invoiceDate', and 'items' 
(an array with 'description', 'quantity', 'unitPrice')."
```

### Expected JSON Structure
```json
{
  "supplier": "Company Name",
  "invoiceDate": "2025-10-09",
  "items": [
    {
      "description": "Product/Service description",
      "quantity": 2,
      "unitPrice": 150.00
    }
  ]
}
```

## Error Handling

### Validation
- Image file must be selected before processing
- Extracted data must be present before invoice creation
- System validates JSON structure and required fields

### Error Messages
- File selection errors
- Image processing failures
- Invoice creation errors
- Network connectivity issues

### User Feedback
- Loading indicators during processing
- Success messages for completed operations
- Error messages with specific failure details
- Color-coded feedback (green for success, red for errors)

## Integration Points

### Backend Services
- **Image Processing**: `McpServices.process#InvoiceImage` - AI-powered data extraction using Gemini
- **Invoice Creation**: `McpServices.create#InvoiceFromData` - Creates invoices using GrowERP services
- **Company Management**: Automatic supplier lookup and creation via GrowERP CompanyServices
- **Product Management**: Automatic product lookup and creation via GrowERP ProductServices
- **File Storage**: Secure image handling and temporary file management

### Frontend Integration
- Integrates with main GrowERP navigation
- Uses shared UI components (`popUp`, `LoadingIndicator`)
- Follows GrowERP localization patterns
- Implements responsive design principles

## Localization

The feature supports internationalization with the following keys:
- `uploadInvoice` - Dialog title
- `pickImage` - Initial image selection button
- `changeImage` - Change selected image button
- `uploadAndProcess` - Process image button
- `extractedData` - Extracted data section title
- `createInvoice` - Final creation button
- `imageProcessed` - Success message for processing
- `invoiceCreated` - Success message for creation

## Security Considerations

### Data Privacy
- Images are processed securely
- Extracted data is validated before storage
- User consent for image processing
- Temporary file cleanup

### Input Validation
- File type verification
- Image size limits
- JSON structure validation
- Sanitization of extracted data

## Performance Considerations

### Image Optimization
- JPEG format for optimal processing
- Reasonable file size limits
- Progressive loading for large images
- Efficient memory management

### Processing Efficiency
- Asynchronous image processing
- Loading states for user feedback
- Error recovery mechanisms
- Timeout handling for long operations

## Future Enhancements

### Planned Features
- Support for additional image formats (PNG, PDF)
- Batch processing of multiple invoices
- Manual correction interface for extracted data
- Template-based extraction for specific vendors
- OCR confidence scoring and validation
- Enhanced product matching algorithms
- Duplicate invoice detection
- Multi-currency support

### Technical Improvements
- Offline processing capabilities
- Enhanced error recovery
- Performance optimizations
- Advanced validation rules
- Audit trail for processed invoices
- Improved product matching using fuzzy search
- Smart supplier deduplication
- Automated invoice categorization

## Testing

### Unit Tests
- Image selection logic
- State management transitions
- Data validation functions
- Error handling scenarios

### Integration Tests
- End-to-end workflow testing
- API integration validation
- UI interaction testing
- Cross-platform compatibility

### User Acceptance Testing
- Workflow usability
- Error message clarity
- Performance benchmarks
- Accessibility compliance

## Troubleshooting

### Common Issues
1. **Image not processing**: Check network connection and file format
2. **Poor extraction quality**: Ensure image is clear and well-lit
3. **Invoice creation fails**: Verify extracted data completeness
4. **Dialog not responsive**: Check for JavaScript errors and reload

### Support Resources
- User documentation
- Video tutorials
- Support ticket system
- Community forums

## API Documentation

### Moqui Services

#### McpServices.process#InvoiceImage
Processes invoice images using AI extraction.
```xml
<in-parameters>
  <parameter name="imageData" type="String" required="true"/>
  <parameter name="prompt" type="String" required="true"/>
  <parameter name="mimeType" type="String" default="image/jpeg"/>
</in-parameters>
<out-parameters>
  <parameter name="extractedData" type="Map"/>
</out-parameters>
```

#### McpServices.create#InvoiceFromData
Creates invoices from extracted data using GrowERP services.
```xml
<in-parameters>
  <parameter name="invoiceData" type="Map" required="true"/>
</in-parameters>
<out-parameters>
  <parameter name="invoice" type="Map"/>
</out-parameters>
```

### Integration Features
- **Automatic Supplier Management**: Finds existing suppliers or creates new ones
- **Automatic Product Catalog**: Creates products from invoice line items
- **GrowERP FinDoc Integration**: Uses native GrowERP invoice system
- **Proper Entity Relationships**: Links invoices to suppliers and products

---

*This document is part of the GrowERP documentation suite. For technical support, please refer to the main GrowERP documentation or contact the development team.*