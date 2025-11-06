# AI-Generated Landing Page Feature Plan

## Overview
This document outlines the comprehensive plan to add an AI-powered landing page generation feature to GrowERP's Landing Page List screen. Users will click a floating action button (FAB) to describe their business, the system will query the internet for relevant information, generate a customized landing page using the general landing page template, and automatically import it into the system.

---

## Executive Summary

**Feature Name:** AI-Generated Landing Page with Internet Research

**Objective:** Enable users to generate professional landing pages in seconds by:
1. Providing a business description
2. Having the system research the business industry/market
3. Generating landing page content using general_landing_page.md as template
4. Creating temporary XML data file (similar to GeneralLandingPageAssessmentImport.xml)
5. Importing the data to create landing page records
6. Displaying the new landing page in the list

**Value Proposition:**
- Dramatically reduces time to create effective landing pages
- Leverages AI and internet research for accurate business positioning
- Automates data generation and import workflow
- Provides immediate results with page refresh

**User Personas:**
- Small business owners wanting quick lead generation tools
- Marketing managers managing multiple landing pages
- Sales teams needing fast turnaround for campaigns

---

## Phase 1: Frontend UI & User Experience

### 1.1 Floating Action Button (FAB) Addition

**Location:** `LandingPageList` screen (landing_page_list.dart)

**Current FAB Stack:**
- Search FAB (heroTag: "landingPageBtn1")
- Add New Landing Page FAB (heroTag: "landingPageBtn2")

**New Addition:**
- AI Generate Landing Page FAB (heroTag: "landingPageBtn3")
- Position: Stack below existing FABs
- Icon: `Icons.auto_awesome` or `Icons.smart_toy`
- Tooltip: "Generate Landing Page with AI"

**Implementation Details:**

```dart
FloatingActionButton(
  key: const Key("generateAILandingPage"),
  heroTag: "landingPageBtn3",
  onPressed: () async {
    await _showAIGenerationDialog(context);
  },
  tooltip: 'Generate Landing Page with AI',
  child: const Icon(Icons.auto_awesome),
)
```

### 1.2 AI Generation Dialog

**Dialog Components:**

1. **Header Section:**
   - Title: "Generate Landing Page with AI"
   - Subtitle: "Describe your business and let AI create a professional landing page"

2. **Business Description Input:**
   - Text field for user to describe their business
   - Placeholder: "E.g., 'I run a digital marketing agency helping small businesses with social media strategy'"
   - Min 20 characters, Max 500 characters
   - Character counter

3. **Optional Advanced Options (Collapsible):**
   - Target Audience: Text field
   - Industry/Market: Dropdown (if predefined)
   - Preferred Tone: Dropdown (Professional, Casual, Inspirational)
   - Number of Sections: Slider (3-7, default 5)

4. **Action Buttons:**
   - "Generate" button (primary)
   - "Cancel" button (secondary)

5. **Processing States:**
   - Loading indicator during generation
   - Progress text: "Researching your business..."
   - Estimated time: ~10-30 seconds

6. **Error Handling:**
   - Display error messages if generation fails
   - Retry button
   - Fallback to manual creation

**UI Framework:**
- Use Dialog widget similar to `LandingPageDetailScreen`
- Responsive design for desktop and tablet
- Mobile-optimized with reduced dialog size

**State Management:**
- Create new BLoC or extend existing: `LandingPageGenerationBloc`
- Events: `GenerateLandingPageRequested`, `GenerationProgress`, `GenerationComplete`
- States: `GenerationInitial`, `GenerationLoading`, `GenerationSuccess`, `GenerationFailure`

---

## Phase 2: Frontend State Management

### 2.1 New BLoC: LandingPageGenerationBloc

**File Location:** `growerp_assessment/lib/src/bloc/landing_page_generation_bloc.dart`

**Events:**

```dart
abstract class LandingPageGenerationEvent extends Equatable {
  const LandingPageGenerationEvent();
}

class GenerateLandingPageRequested extends LandingPageGenerationEvent {
  final String businessDescription;
  final String? targetAudience;
  final String? industry;
  final String? tone; // 'professional', 'casual', 'inspirational'
  final int? numSections; // 3-7

  const GenerateLandingPageRequested({
    required this.businessDescription,
    this.targetAudience,
    this.industry,
    this.tone = 'professional',
    this.numSections = 5,
  });

  @override
  List<Object?> get props => [
    businessDescription, 
    targetAudience, 
    industry, 
    tone,
    numSections
  ];
}

class GenerationCancelled extends LandingPageGenerationEvent {
  const GenerationCancelled();

  @override
  List<Object?> get props => [];
}
```

**States:**

```dart
enum GenerationStatus { 
  initial, 
  loading, 
  researchingBusiness,
  generatingContent,
  creatingXml,
  importing,
  success, 
  failure 
}

class LandingPageGenerationState extends Equatable {
  final GenerationStatus status;
  final String? message;
  final int? progressPercent;
  final String? generatedXmlPath;
  final LandingPage? generatedLandingPage;

  const LandingPageGenerationState({
    this.status = GenerationStatus.initial,
    this.message,
    this.progressPercent = 0,
    this.generatedXmlPath,
    this.generatedLandingPage,
  });

  LandingPageGenerationState copyWith({
    GenerationStatus? status,
    String? message,
    int? progressPercent,
    String? generatedXmlPath,
    LandingPage? generatedLandingPage,
  }) {
    return LandingPageGenerationState(
      status: status ?? this.status,
      message: message ?? this.message,
      progressPercent: progressPercent ?? this.progressPercent,
      generatedXmlPath: generatedXmlPath ?? this.generatedXmlPath,
      generatedLandingPage: generatedLandingPage ?? this.generatedLandingPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    progressPercent,
    generatedXmlPath,
    generatedLandingPage,
  ];
}
```

**BLoC Implementation:**

```dart
class LandingPageGenerationBloc 
  extends Bloc<LandingPageGenerationEvent, LandingPageGenerationState> {
  
  final RestClient restClient;
  final String classificationId;
  final String ownerPartyId; // Current user's owner party ID

  LandingPageGenerationBloc({
    required this.restClient,
    required this.classificationId,
    required this.ownerPartyId,
  }) : super(const LandingPageGenerationState()) {
    on<GenerateLandingPageRequested>(_onGenerateLandingPage);
    on<GenerationCancelled>(_onGenerationCancelled);
  }

  Future<void> _onGenerateLandingPage(
    GenerateLandingPageRequested event,
    Emitter<LandingPageGenerationState> emit,
  ) async {
    emit(state.copyWith(
      status: GenerationStatus.loading,
      message: 'Starting generation...',
      progressPercent: 0,
    ));

    try {
      // Step 1: Call backend to research business & generate content
      emit(state.copyWith(
        status: GenerationStatus.researchingBusiness,
        message: 'Researching your business...',
        progressPercent: 20,
      ));

      final generationResult = 
        await restClient.generateLandingPageWithAI(
          businessDescription: event.businessDescription,
          targetAudience: event.targetAudience,
          industry: event.industry,
          tone: event.tone ?? 'professional',
          numSections: event.numSections ?? 5,
          ownerPartyId: ownerPartyId,
        );

      emit(state.copyWith(
        status: GenerationStatus.generatingContent,
        message: 'Generating content...',
        progressPercent: 50,
      ));

      // Step 2: Create XML file on backend
      emit(state.copyWith(
        status: GenerationStatus.creatingXml,
        message: 'Creating data file...',
        progressPercent: 70,
      ));

      // Step 3: Import XML data
      emit(state.copyWith(
        status: GenerationStatus.importing,
        message: 'Importing landing page...',
        progressPercent: 85,
      ));

      final importResult = await restClient.importGeneratedLandingPage(
        xmlPath: generationResult['xmlPath'],
        ownerPartyId: ownerPartyId,
      );

      emit(state.copyWith(
        status: GenerationStatus.success,
        message: 'Landing page created successfully!',
        progressPercent: 100,
        generatedXmlPath: generationResult['xmlPath'],
        generatedLandingPage: LandingPage.fromJson(
          importResult['landingPage'],
        ),
      ));

    } catch (e) {
      emit(state.copyWith(
        status: GenerationStatus.failure,
        message: 'Error: ${e.toString()}',
        progressPercent: 0,
      ));
    }
  }

  Future<void> _onGenerationCancelled(
    GenerationCancelled event,
    Emitter<LandingPageGenerationState> emit,
  ) async {
    emit(const LandingPageGenerationState(
      status: GenerationStatus.initial,
    ));
  }
}
```

### 2.2 Update LandingPageList to Use New BLoC

**Changes to landing_page_list.dart:**

1. Add LandingPageGenerationBloc provider
2. Listen to generation events
3. Trigger landing page refresh on success
4. Update FAB section to include AI generation button

---

## Phase 3: Backend API Endpoints

### 3.1 New REST API Endpoints

**Endpoint 1: Generate Landing Page Content**

```
POST /rest/s1/mcp/generateLandingPageWithAI
Content-Type: application/json

Request Body:
{
  "businessDescription": "String (required, 20-500 chars)",
  "targetAudience": "String (optional)",
  "industry": "String (optional)",
  "tone": "String (optional, enum: professional|casual|inspirational)",
  "numSections": "Integer (optional, 3-7, default 5)",
  "ownerPartyId": "String (required - current user's owner)"
}

Response:
{
  "success": true,
  "xmlPath": "/tmp/landing_page_import_UUID.xml",
  "landingPageId": "LP_UUID",
  "estimatedImportTime": "5-10 seconds",
  "contentData": {
    "title": "Generated title",
    "headline": "Generated headline",
    "subheading": "Generated subheading",
    "sections": [...],
    "credibility": {...},
    "cta": {...}
  }
}
```

**Endpoint 2: Import Generated Landing Page**

```
POST /rest/s1/mcp/importGeneratedLandingPage
Content-Type: application/json

Request Body:
{
  "xmlPath": "String (temp XML file path)",
  "ownerPartyId": "String"
}

Response:
{
  "success": true,
  "message": "Landing page imported successfully",
  "landingPage": {
    "landingPageId": "LP_UUID",
    "pseudoId": "generated-landing-page-UUID",
    "title": "...",
    "ownerPartyId": "..."
  },
  "itemsCreated": {
    "landingPages": 1,
    "sections": 5,
    "credibilityItems": 3,
    "questions": 15
  }
}
```

### 3.2 Backend Service Implementation

**File:** `moqui/runtime/component/growerp/service/LandingPageAIServices.xml`

**Service 1: generateLandingPageWithAI**

```xml
<service verb="generate" noun="LandingPageWithAI" authenticate="true">
  <description>Generate landing page content using Gemini AI and internet research</description>
  <in-parameters>
    <parameter name="businessDescription" type="String" required="true"/>
    <parameter name="targetAudience" type="String"/>
    <parameter name="industry" type="String"/>
    <parameter name="tone" type="String" default="professional"/>
    <parameter name="numSections" type="Integer" default="5"/>
    <parameter name="ownerPartyId" type="String" required="true"/>
  </in-parameters>
  <out-parameters>
    <parameter name="xmlPath" type="String"/>
    <parameter name="landingPageId" type="String"/>
    <parameter name="contentData" type="Map"/>
  </out-parameters>
  <actions>
    <script location="component://growerp/service/generateLandingPageWithAI.groovy"/>
  </actions>
</service>
```

**Service 2: importGeneratedLandingPage**

```xml
<service verb="import" noun="GeneratedLandingPage" authenticate="true">
  <description>Import generated landing page XML data into system</description>
  <in-parameters>
    <parameter name="xmlPath" type="String" required="true"/>
    <parameter name="ownerPartyId" type="String" required="true"/>
  </in-parameters>
  <out-parameters>
    <parameter name="landingPage" type="Map"/>
    <parameter name="itemsCreated" type="Map"/>
  </out-parameters>
  <actions>
    <script location="component://growerp/service/importGeneratedLandingPage.groovy"/>
  </actions>
</service>
```

### 3.3 Groovy Implementation Files

**File 1: generateLandingPageWithAI.groovy**

**Key Tasks:**
1. Validate user owns the ownerPartyId
2. Use Gemini API to research business
3. Generate landing page structure based on general_landing_page.md template
4. Create temporary XML file with landing page data
5. Return file path and generated content

**Pseudo-code:**

```groovy
// 1. Validate ownership
def user = ec.user
def partyId = user.userAccount.partyId

// 2. Call Gemini with research prompt
def geminiPrompt = """
Based on this business description and the general_landing_page.md template:

Business Description: ${businessDescription}
Target Audience: ${targetAudience ?: 'Not specified'}
Industry: ${industry ?: 'Determine from description'}
Desired Tone: ${tone}

Generate a complete landing page structure with:
1. Compelling hook (headline)
2. Clear subheading
3. ${numSections} distinct sections with content
4. Value propositions (3 key areas)
5. Credibility section with statistics
6. Call-to-action
7. Assessment questions (optional)

Return as JSON following the LandingPage model structure.
"""

def geminiResult = ec.service.call('McpServices.process#InvoiceImage', [
  imageData: null, // For text-only, we can use alternative Gemini endpoint
  prompt: geminiPrompt,
  // Or use direct HTTP call to Gemini API
])

// 3. Extract generated content
def landingPageContent = parseJsonResponse(geminiResult)

// 4. Create XML file with EntityFacadeXmlUtils
def xmlContent = generateLandingPageXML(landingPageContent, ownerPartyId)
def tempFile = new File("/tmp/landing_page_${UUID.randomUUID()}.xml")
tempFile.write(xmlContent)

// 5. Return results
context.put('xmlPath', tempFile.absolutePath)
context.put('landingPageId', landingPageContent.pseudoId)
context.put('contentData', landingPageContent)
```

**File 2: importGeneratedLandingPage.groovy**

**Key Tasks:**
1. Validate XML file exists and is readable
2. Parse XML and extract landing page entities
3. Use EntityImportFacade to import data
4. Ensure ownerPartyId is set on all entities
5. Return import statistics
6. Clean up temporary XML file

**Pseudo-code:**

```groovy
// 1. Validate file
File xmlFile = new File(xmlPath)
if (!xmlFile.exists()) {
  ec.message.addError("XML file not found: ${xmlPath}")
  return
}

// 2. Parse and prepare for import
def entityFacade = ec.entity
def importData = new XmlSlurper().parse(xmlFile)

// 3. Import using EntityImportFacade
def importResult = entityFacade.importEntities(xmlFile.text, null, null)

// 4. Count created items
def createdCount = [
  landingPages: importResult.landingPages?.size() ?: 0,
  sections: importResult.sections?.size() ?: 0,
  credibilityItems: importResult.credibilityItems?.size() ?: 0,
  questions: importResult.questions?.size() ?: 0,
]

// 5. Get created landing page
def landingPage = entityFacade.find('LandingPage')
  .condition('ownerPartyId', ownerPartyId)
  .orderBy('-createdDate')
  .first()

// 6. Clean up
xmlFile.delete()

context.put('landingPage', landingPage?.toMap())
context.put('itemsCreated', createdCount)
```

---

## Phase 4: XML Data Generation

### 4.1 XML Template Structure

**File:** `moqui/runtime/component/growerp/service/templates/LandingPageGenerationTemplate.xml`

**Structure (based on GeneralLandingPageAssessmentImport.xml):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
AI-Generated Landing Page Import Data
Generated: ${timestamp}
Owner: ${ownerPartyId}
Business Description: ${businessDescription}
-->
<entity-facade-xml type="seed-initial">

  <!-- Landing Page -->
  <growerp.landing.LandingPage landingPageId="${landingPageId}"
    pseudoId="${pseudoId}"
    ownerPartyId="${ownerPartyId}"
    title="${title}"
    headline="${headline}"
    subheading="${subheading}"
    hookType="${hookType}"
    status="DRAFT"
    createdDate="${now}"
    createdByUserLogin="${username}"/>

  <!-- Page Sections (dynamic count) -->
  <growerp.landing.PageSection pageSequence="${sequence}"
    sectionTitle="${sectionTitle}"
    sectionContent="${sectionContent}"
    landingPageId="${landingPageId}"
    createdDate="${now}"
    createdByUserLogin="${username}"/>

  <!-- Credibility Section -->
  <growerp.landing.CredibilityInfo .../>

  <!-- CTA -->
  <growerp.landing.PrimaryCTA .../>

  <!-- Assessment (optional) -->
  <growerp.assessment.Assessment .../>

</entity-facade-xml>
```

### 4.2 Dynamic XML Generation

**File:** `moqui/runtime/component/growerp/service/LandingPageXMLGenerator.groovy`

**Key Methods:**

```groovy
class LandingPageXMLGenerator {
  
  static String generateXML(Map contentData, String ownerPartyId) {
    def sb = new StringBuilder()
    
    // Header
    sb.append(generateHeader(contentData))
    
    // Landing Page Entity
    sb.append(generateLandingPageEntity(contentData, ownerPartyId))
    
    // Sections
    contentData.sections?.eachWithIndex { section, idx ->
      sb.append(generateSectionEntity(section, contentData.landingPageId, idx))
    }
    
    // Credibility
    if (contentData.credibility) {
      sb.append(generateCredibilityEntity(contentData))
    }
    
    // CTA
    if (contentData.cta) {
      sb.append(generateCTAEntity(contentData))
    }
    
    // Assessment (optional)
    if (contentData.includeAssessment) {
      sb.append(generateAssessmentEntity(contentData))
    }
    
    sb.append('</entity-facade-xml>')
    return sb.toString()
  }
}
```

---

## Phase 5: Internet Research Integration

### 5.1 Research Strategy

**Data Sources:**
1. **Gemini API** (primary): For content generation and research synthesis
2. **Public APIs** (optional):
   - SerpAPI / Google Custom Search for industry data
   - Wikipedia API for industry information
   - News APIs for market trends

**Research Prompt Construction:**

```groovy
def createResearchPrompt(businessDescription, industry, targetAudience) {
  return """
Research and generate landing page content for the following business:

BUSINESS DESCRIPTION: ${businessDescription}

TARGET AUDIENCE: ${targetAudience ?: 'General audience'}

INDUSTRY: ${industry ?: 'Determine from description'}

TASK:
1. Research the industry and market for this business
2. Identify 3-5 key value propositions relevant to the business type
3. Generate compelling copy following these principles from general_landing_page.md:
   - Hook: Use a "Results Hook" that poses a question
   - Subheading: Clear guidance on next steps
   - Value Proposition: 3 pillars of success for this industry
   - Credibility: Industry statistics, background info
   - CTA: Clear call-to-action

CONSTRAINTS:
- Keep content professional and engaging
- Use industry-specific terminology
- Include realistic statistics
- Suggest 3-5 page sections
- Generate 8-12 assessment questions if applicable

RETURN FORMAT: JSON with structure matching LandingPage model
"""
}
```

### 5.2 Gemini API Integration

**Enhancement to existing processInvoiceImage service:**

Create a new generic service `McpServices.process#AnyContent` that supports:
- Text-only processing
- Image + text processing
- Long-form content generation

---

## Phase 6: Frontend Dialog Implementation

### 6.1 AI Generation Dialog Component

**File:** `growerp_assessment/lib/src/screens/generate_landing_page_dialog.dart`

**Component Structure:**

```dart
class GenerateLandingPageDialog extends StatefulWidget {
  final String ownerPartyId;
  final Function(LandingPage) onSuccess;
  
  const GenerateLandingPageDialog({
    required this.ownerPartyId,
    required this.onSuccess,
  });

  @override
  State<GenerateLandingPageDialog> createState() => 
    _GenerateLandingPageDialogState();
}

class _GenerateLandingPageDialogState extends State<GenerateLandingPageDialog> {
  final _descriptionController = TextEditingController();
  final _audienceController = TextEditingController();
  bool _advancedExpanded = false;
  String? _selectedTone = 'professional';
  int _selectedSections = 5;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxHeight: 700),
        child: BlocProvider<LandingPageGenerationBloc>(
          create: (context) => LandingPageGenerationBloc(
            restClient: context.read<RestClient>(),
            classificationId: 'AppAdmin', // From context
            ownerPartyId: widget.ownerPartyId,
          ),
          child: BlocConsumer<LandingPageGenerationBloc, 
            LandingPageGenerationState>(
            listener: (context, state) {
              if (state.status == GenerationStatus.success) {
                widget.onSuccess(state.generatedLandingPage!);
                Navigator.of(context).pop();
              } else if (state.status == GenerationStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message ?? 'Error')),
                );
              }
            },
            builder: (context, state) {
              if (state.status == GenerationStatus.loading ||
                  state.status == GenerationStatus.researchingBusiness ||
                  state.status == GenerationStatus.generatingContent ||
                  state.status == GenerationStatus.creatingXml ||
                  state.status == GenerationStatus.importing) {
                return _buildProgressView(context, state);
              }
              
              return _buildFormView(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, LandingPageGenerationState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generate Landing Page with AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your business and let AI create a professional landing page',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Business Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Business Description*',
                hintText: 'E.g., I run a digital marketing agency...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Target Audience
            TextField(
              controller: _audienceController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Target Audience (optional)',
                hintText: 'E.g., Small business owners...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Advanced Options
            ExpansionTile(
              title: const Text('Advanced Options'),
              onExpansionChanged: (value) => setState(() => _advancedExpanded = value),
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTone,
                  items: ['professional', 'casual', 'inspirational']
                    .map((tone) => DropdownMenuItem(
                      value: tone,
                      child: Text(tone),
                    ))
                    .toList(),
                  onChanged: (value) => setState(() => _selectedTone = value),
                  decoration: const InputDecoration(
                    labelText: 'Tone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _selectedSections.toDouble(),
                  min: 3,
                  max: 7,
                  divisions: 4,
                  label: 'Sections: $_selectedSections',
                  onChanged: (value) => setState(() => _selectedSections = value.toInt()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _descriptionController.text.length >= 20
                    ? () => _generateLandingPage(context)
                    : null,
                  child: const Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(BuildContext context, LandingPageGenerationState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: (state.progressPercent ?? 0) / 100),
          const SizedBox(height: 24),
          Text(
            state.message ?? 'Processing...',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.progressPercent}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _generateLandingPage(BuildContext context) {
    context.read<LandingPageGenerationBloc>().add(
      GenerateLandingPageRequested(
        businessDescription: _descriptionController.text,
        targetAudience: _audienceController.text.isEmpty 
          ? null 
          : _audienceController.text,
        tone: _selectedTone,
        numSections: _selectedSections,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _audienceController.dispose();
    super.dispose();
  }
}
```

### 6.2 Trigger from Landing Page List

**Update landing_page_list.dart:**

```dart
FloatingActionButton(
  key: const Key("generateAILandingPage"),
  heroTag: "landingPageBtn3",
  onPressed: () async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: _landingPageBloc,
          child: GenerateLandingPageDialog(
            ownerPartyId: ownerPartyId,
            onSuccess: (landingPage) {
              // Refresh the list
              _landingPageBloc.add(const LandingPageLoad());
              
              // Show success message
              HelperFunctions.showMessage(
                context,
                'Landing page "${landingPage.title}" created successfully!',
                Colors.green,
              );
            },
          ),
        );
      },
    );
  },
  tooltip: 'Generate Landing Page with AI',
  child: const Icon(Icons.auto_awesome),
)
```

---

## Phase 7: Integration Points

### 7.1 RestClient Updates

**File:** `growerp_models/lib/src/rest_client/rest_client.dart`

**New Methods:**

```dart
@POST('/rest/s1/mcp/generateLandingPageWithAI')
Future<Map<String, dynamic>> generateLandingPageWithAI(
  @Field('businessDescription') String businessDescription,
  @Field('targetAudience') String? targetAudience,
  @Field('industry') String? industry,
  @Field('tone') String tone,
  @Field('numSections') int numSections,
  @Field('ownerPartyId') String ownerPartyId,
);

@POST('/rest/s1/mcp/importGeneratedLandingPage')
Future<Map<String, dynamic>> importGeneratedLandingPage(
  @Field('xmlPath') String xmlPath,
  @Field('ownerPartyId') String ownerPartyId,
);
```

### 7.2 Authentication & Ownership Validation

- Verify user owns the ownerPartyId
- Use user's credentials for API calls
- Ensure generated landing page is assigned to correct owner
- Log all generation attempts for audit trail

### 7.3 Error Scenarios & Fallbacks

| Scenario | Handling |
|----------|----------|
| Gemini API unavailable | Show error, offer manual creation |
| Invalid business description | Show validation error, allow retry |
| XML generation fails | Log error, offer manual creation |
| Import fails | Rollback, show detailed error |
| Network timeout | Retry with exponential backoff |
| Rate limiting | Queue and retry, show estimated wait |

---

## Phase 8: Data Flow Diagram

```
┌─────────────────────────────────────┐
│ LandingPageList Screen              │
│  - Displays all landing pages       │
│  - Has 3 FABs (Search, Add, AI Gen) │
└────────────┬────────────────────────┘
             │ User clicks "AI Generate"
             ▼
┌─────────────────────────────────────┐
│ GenerateLandingPageDialog           │
│  - Collects business description    │
│  - Optional: audience, tone, sections
└────────────┬────────────────────────┘
             │ Submit
             ▼
┌─────────────────────────────────────┐
│ LandingPageGenerationBloc           │
│  - Events: GenerateLandingPageRequest
│  - States: loading, processing      │
└────────────┬────────────────────────┘
             │ ADD event
             ▼
┌─────────────────────────────────────┐
│ Frontend → Backend REST Call        │
│ POST /rest/s1/mcp/generateLP...     │
└────────────┬────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Backend: generateLandingPageWithAI   │
│  1. Validate user ownership          │
│  2. Call Gemini API (research)       │
│  3. Generate content from template   │
│  4. Create temporary XML file        │
│  5. Return xmlPath & content         │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Frontend receives generation result  │
│ Calls importGeneratedLandingPage     │
│ POST /rest/s1/mcp/importLP...        │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Backend: importGeneratedLandingPage  │
│  1. Validate ownership               │
│  2. Parse temp XML file              │
│  3. Import using EntityImportFacade  │
│  4. Delete temp XML file             │
│  5. Return created landing page      │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Frontend receives import result      │
│  - Show success message              │
│  - Update BLoC state                 │
│  - Close dialog                      │
│  - Refresh landing page list         │
└──────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ LandingPageList refreshed            │
│  - New landing page appears in list  │
│  - Shows as DRAFT status             │
│  - User can edit/publish             │
└──────────────────────────────────────┘
```

---

## Phase 9: Testing Strategy

### 9.1 Unit Tests

**Frontend:**
- Test LandingPageGenerationBloc events/states
- Test dialog validation logic
- Test form input constraints

**Backend:**
- Test Gemini API integration
- Test XML generation
- Test import validation

### 9.2 Integration Tests

**End-to-End:**
1. Open landing page list
2. Click AI generate FAB
3. Enter business description
4. Submit form
5. Monitor progress
6. Verify landing page created
7. Verify page appears in list

### 9.3 Edge Cases

- Empty business description
- Very long descriptions (>500 chars)
- Special characters in input
- Network failures during processing
- Concurrent generation requests
- Large numbers of sections

---

## Phase 10: Performance Considerations

### 10.1 Optimization

**Frontend:**
- Debounce character counter updates
- Cache dialog component
- Lazy load advanced options

**Backend:**
- Cache Gemini responses for similar businesses
- Async processing for XML generation
- Connection pooling for Gemini API

### 10.2 Scaling

- Queue system for multiple concurrent requests
- Rate limiting per user/day
- Background processing for imports
- Temporary file cleanup service

---

## Phase 11: Security & Compliance

### 11.1 Security Measures

1. **Authentication:** Verify user before generation
2. **Authorization:** Validate ownerPartyId ownership
3. **Data Privacy:** Don't log sensitive business descriptions
4. **API Keys:** Store Gemini API key securely (environment variable)
5. **File Handling:** Secure temp file creation/deletion
6. **Input Validation:** Sanitize all user inputs

### 11.2 Audit Trail

- Log all generation requests with:
  - User ID
  - Timestamp
  - Business description (summary)
  - Generated landing page ID
  - Success/failure status

---

## Implementation Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1-2: UI & BLoC | 1-2 days | - |
| Phase 3: API Endpoints | 1-2 days | Phase 1-2 complete |
| Phase 4-5: Backend Logic | 2-3 days | Phase 3 complete |
| Phase 6: Dialog UI | 1 day | Phase 1-2 complete |
| Phase 7: Integration | 1 day | All phases complete |
| Phase 8-11: Testing & Polish | 2-3 days | Phases 1-7 complete |
| **Total** | **9-13 days** | - |

---

## Success Metrics

1. **User Adoption:** % of users using AI generation
2. **Generation Success Rate:** % of successful generations
3. **Time Saved:** Average time to create landing page
4. **Content Quality:** User satisfaction with generated content
5. **System Performance:** API response time < 30 seconds
6. **Error Rate:** < 1% failure rate

---

## Future Enhancements

1. **Batch Generation:** Generate multiple variations
2. **Template Variations:** Different landing page styles
3. **A/B Testing:** Suggest variations for testing
4. **Analytics Integration:** Track performance metrics
5. **Feedback Loop:** Learn from user edits to improve generation
6. **Industry Templates:** Pre-built templates for common industries
7. **Multilingual Support:** Generate in different languages
8. **SEO Optimization:** Include SEO recommendations

---

## Rollout Strategy

1. **Phase 1:** Internal testing with development team
2. **Phase 2:** Beta release to select users
3. **Phase 3:** Gather feedback and iterate
4. **Phase 4:** General availability release

---

## References

- General Landing Page Template: `flutter/packages/landing_page/general_landing_page.md`
- XML Import Example: `moqui/runtime/component/growerp/data/GeneralLandingPageAssessmentImport.xml`
- LandingPageList: `growerp_assessment/lib/src/screens/landing_page_list.dart`
- Similar Features: Invoice Scan (Gemini integration), Assessment generation

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-06  
**Status:** Draft - Ready for Implementation Planning
