# Landing Page & Assessment Architecture Deep Dive

**Version:** 1.0  
**Purpose:** Technical architecture reference for implementation teams

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PUBLIC LANDING PAGE LAYER                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User → LandingPageScreen (Hero + CTA) → Assessment Flow                   │
│         ↓                                                                    │
│    [Contact Info] → [Best Practices] → [Qualification] → [Results]         │
│                                                                             │
│  Results Flow:                                                              │
│    Score Reveal → Insights → Qualification Summary → Thank You + CTA       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SCORING & LEAD CAPTURE ENGINE                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Assessment Answers                                                         │
│    ├─ Contact Info (Name, Email, Phone, Location)                         │
│    ├─ Best Practices (10 questions) → Score Calculation                    │
│    │   Score = (Yes Count / 10) × 100%                                     │
│    │                                                                       │
│    │   Cold:  0-40   →  CTA: Learning Resources                           │
│    │   Warm: 40-70   →  CTA: Group Presentation                           │
│    │   Hot:  70-100  →  CTA: 1:1 Consultation                             │
│    │                                                                       │
│    └─ Qualification (5 Big Five) → Lead Enrichment                         │
│       ├─ Situation (Growth Stage)                                          │
│       ├─ Outcome (Desired Result)                                          │
│       ├─ Obstacle (Primary Challenge)                                      │
│       ├─ Solution (Budget/Preference)                                      │
│       └─ Open (Additional Info)                                            │
│                                                                             │
│  Insight Generation:                                                        │
│    3 insights mapped from question answers + predefined templates           │
│                                                                             │
│  Lead Object Created:                                                       │
│    {name, email, phone, location, score, status, insights, nextStepType}   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                   MARKETING PACKAGE LEAD MANAGEMENT                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Lead → Opportunity (mantle-udm)                                            │
│    ├─ Status: Cold/Warm/Hot                                                │
│    ├─ Score: 0-100%                                                        │
│    ├─ Source: assessment@landing-page-slug                                 │
│    ├─ Recommended Action: consultation/presentation/content                │
│    └─ Lead List View (Admin Dashboard)                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ADMIN CONFIGURATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Landing Page Builder:                                                      │
│    ├─ Hook (Frustration/Results)                                           │
│    ├─ Headline + Subheading                                                │
│    ├─ Value Areas (3 configurable sections)                                │
│    ├─ Credibility Section (Bio + Stats)                                    │
│    ├─ Primary CTA Configuration                                            │
│    └─ Privacy Policy Link                                                  │
│                                                                             │
│  Assessment Builder:                                                        │
│    ├─ Contact Questions (3: Name, Email, Phone)                            │
│    ├─ Best Practices Questions (10 customizable)                           │
│    ├─ Qualification Questions (5 Big Five)                                 │
│    └─ Scoring Rules (3 thresholds: Cold/Warm/Hot)                          │
│                                                                             │
│  Insights Mapper:                                                           │
│    ├─ Template-based insight generation                                    │
│    ├─ Conditional logic (if Q3=No, then Insight="...")                     │
│    └─ Manual override support                                              │
│                                                                             │
│  Leads Dashboard:                                                           │
│    ├─ Real-time lead count + distribution                                  │
│    ├─ Filterable lead list (score, status, date)                           │
│    ├─ Lead export (CSV/JSON)                                               │
│    └─ Lead status management                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Relationship Diagram

```
Landing Page Package (Public)
├─ LandingPageBloc
│  ├─ LoadLandingPageEvent
│  │  └─ LandingPageService.getLandingPage(pseudoId)
│  │     └─ REST: GET /api/v1/landing-page/{pseudoId}
│  │        └─ Moqui: LandingPageServices::getLandingPage
│  │           └─ Entity: LandingPage + ValueArea + CredibilityInfo
│  │
│  └─ State: LandingPageSuccess(page)
│     └─ LandingPageScreen renders hero section
│
├─ AssessmentBloc
│  ├─ StartAssessmentEvent
│  │  └─ LandingPageService.getAssessmentForLandingPage(landingPageId)
│  │
│  ├─ SubmitContactInfoEvent
│  │  └─ AssessmentBloc stores temporarily (no DB write yet)
│  │
│  ├─ SubmitBestPracticesEvent
│  │  └─ AssessmentScoringService.calculateScore(answers)
│  │
│  ├─ SubmitQualificationEvent
│  │  └─ AssessmentScoringService.determineNextStep(score, budget)
│  │
│  └─ State: AssessmentComplete(result)
│     └─ ThankyouScreen + Lead Capture happens here
│
└─ LeadCaptureBloc
   ├─ CaptureLead(result)
   │  └─ LeadCaptureService.convertAssessmentToLead(result)
   │     ├─ REST: POST /api/v1/assessment/submit
   │     └─ Moqui: LeadServices::createAssessmentLead
   │        ├─ Create Opportunity (Marketing)
   │        ├─ Create AssessmentResult (growerp)
   │        └─ Return Lead object
   │
   └─ State: LeadCaptureSuccess(lead)
      └─ Trigger notifications, analytics


Admin Package (Authenticated)
├─ LandingPageAdminBloc
│  ├─ ListLandingPagesEvent
│  │  └─ REST: GET /api/v1/admin/landing-pages?companyId={id}
│  │
│  ├─ CreateLandingPageEvent
│  │  └─ REST: POST /api/v1/admin/landing-pages
│  │
│  ├─ UpdateLandingPageEvent
│  │  └─ REST: PUT /api/v1/admin/landing-pages/{pseudoId}
│  │
│  └─ DeleteLandingPageEvent
│     └─ REST: DELETE /api/v1/admin/landing-pages/{pseudoId}
│
├─ AssessmentAdminBloc
│  ├─ BuildAssessmentEvent (Questions, Options, Weights)
│  ├─ ConfigureScoringEvent (Thresholds & Templates)
│  └─ MapInsightsEvent (Condition → Insight mapping)
│
└─ LeadsAdminBloc
   ├─ ListLeadsEvent (with filters: score, status, date, LP)
   ├─ ViewLeadDetailsEvent
   ├─ UpdateLeadStatusEvent
   └─ ExportLeadsEvent
```

---

## State Management Flow

### Assessment Completion Flow

```
AssessmentBloc: Initial State
    ↓
User enters name/email/phone
    ↓
SubmitContactInfoEvent
    └─→ AssessmentBloc.add(SubmitContactInfoEvent)
        └─ State: ContactInfoForm ✓
           Emit: ContactInfoComplete → Show Step 2
    ↓
User answers 10 best practices questions
    ↓
SubmitBestPracticesEvent
    └─→ AssessmentBloc.add(SubmitBestPracticesEvent)
        ├─ AssessmentScoringService.calculateScore()
        │  └─ Iterate through answers
        │     Count "Yes" answers (weight 10 each)
        │     Score = (YesCount / 10) × 100
        │
        └─ Determine Status:
           if score >= 70: "Hot"
           else if score >= 40: "Warm"
           else: "Cold"
        
        └─ State: BestPracticesForm ✓
           Emit: BestPracticesComplete → Show Step 3
    ↓
User answers 5 qualification questions
    ↓
SubmitQualificationEvent
    └─→ AssessmentBloc.add(SubmitQualificationEvent)
        ├─ Store qualification answers in state
        ├─ AssessmentScoringService.generateInsights()
        │  └─ Map 3 insights based on negative answers
        │
        ├─ AssessmentScoringService.determineNextStep()
        │  ├─ if Hot + HighBudget: "consultation"
        │  ├─ if Warm or MediumBudget: "presentation"
        │  └─ if Cold or LowBudget: "content"
        │
        └─ State: QualificationForm ✓
           Emit: AssessmentComplete(result)
               → Show Results Screens
    ↓
AssessmentComplete State
    ├─ Show Score Reveal Screen
    │  └─ Circular progress gauge + Status label
    │
    ├─ Show Insights Screen
    │  └─ 3 key insights from answers
    │
    ├─ Show Qualification Summary
    │  └─ Recap of Q13-Q17 answers
    │
    └─ Show Thank You Screen
       └─ Dynamic CTA based on status
          ├─ Hot: "Schedule Consultation" → Calendly
          ├─ Warm: "Join Presentation" → Event URL
          └─ Cold: "Watch Resources" → Video/Blog
    ↓
LeadCaptureBloc.add(CaptureLead(result))
    ├─ LeadCaptureService.convertAssessmentToLead()
    ├─ Send POST to backend: /api/v1/assessment/submit
    │  ├─ Backend: Create AssessmentResult row
    │  ├─ Backend: Create Opportunity in Marketing
    │  └─ Response: Lead object with ID
    │
    └─ State: LeadCaptureSuccess(lead)
       └─ Show final CTA button
          "Thank You - Your lead saved"
```

---

## Data Validation & Error Handling

### Contact Info Validation
```dart
class ContactInfoValidator {
  // Name: Non-empty, 2-50 chars
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    if (value.length > 50) return 'Name must be less than 50 characters';
    return null;
  }
  
  // Email: Valid email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Invalid email format';
    return null;
  }
  
  // Phone: Optional but must be valid if provided
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length < 10) return 'Phone must be at least 10 digits';
    return null;
  }
}
```

### Question Answer Validation
```dart
class QuestionValidator {
  // Best Practices: Must select Yes or No
  static String? validateBestPractice(String? answer) {
    if (answer == null || answer.isEmpty) return 'This question is required';
    if (!answer.contains('Yes') && !answer.contains('No')) {
      return 'Please select Yes or No';
    }
    return null;
  }
  
  // Qualification: Must select from predefined options
  static String? validateQualification(String? answer, List<String> options) {
    if (answer == null || answer.isEmpty) return 'This question is required';
    if (!options.contains(answer)) return 'Invalid selection';
    return null;
  }
}
```

---

## Error Handling Strategy

### API Error Responses

```json
{
  "error": {
    "code": "ASSESSMENT_NOT_FOUND",
    "message": "The assessment could not be found",
    "statusCode": 404,
    "timestamp": "2025-10-23T10:30:00Z"
  }
}
```

### Frontend Error Handling

```dart
// In LeadCaptureBloc listener
if (state.status == LeadCaptureStatus.failure) {
  switch (state.errorCode) {
    case 'LEAD_ALREADY_EXISTS':
      // Show: "You've already submitted this assessment"
      // CTA: "View your results" (redirect to results)
      break;
    
    case 'INVALID_EMAIL':
      // Show: "Please use a valid email address"
      // CTA: "Go back and fix" (return to contact form)
      break;
    
    case 'SERVER_ERROR':
      // Show: "Something went wrong. Please try again."
      // CTA: "Retry" (with exponential backoff)
      break;
    
    default:
      // Show generic error
      break;
  }
}
```

---

## Multi-Tenant Isolation

### Tenant Context

Every request must include company context:

```dart
class TenantContext {
  final String companyPartyId;
  final String userPartyId; // For admin endpoints
  
  // Verify tenant ownership
  Future<bool> isAuthorizedFor(String landingPageId) async {
    final lp = await repository.getLandingPage(landingPageId);
    return lp.companyPartyId == this.companyPartyId;
  }
}
```

### Query Isolation

All queries filtered by company:

```dart
// Frontend service
Future<List<LandingPage>> listLandingPages(String companyPartyId) {
  return restClient.get(
    '/api/v1/admin/landing-pages',
    queryParameters: {'companyId': companyPartyId},
  );
}

// Backend Moqui
<service verb="list" noun="LandingPages">
  <in-parameters>
    <parameter name="companyPartyId" type="String" required="true"/>
  </in-parameters>
  <!-- Query: SELECT * FROM LandingPage WHERE companyPartyId = ? -->
</service>
```

---

## Performance Optimizations

### Frontend Caching

```dart
class LandingPageCacheService {
  static const Duration CACHE_DURATION = Duration(hours: 24);
  final Map<String, CachedPage> _cache = {};
  
  Future<LandingPage> get(String pseudoId) async {
    final cached = _cache[pseudoId];
    
    if (cached != null && 
        DateTime.now().difference(cached.fetchedAt) < CACHE_DURATION) {
      return cached.page;
    }
    
    // Fetch fresh
    final page = await restClient.getLandingPage(pseudoId);
    _cache[pseudoId] = CachedPage(page, DateTime.now());
    return page;
  }
  
  void invalidate(String pseudoId) => _cache.remove(pseudoId);
}
```

### Backend Query Optimization

```sql
-- Indexes for common queries
CREATE INDEX idx_landing_page_company 
ON LandingPage(companyPartyId);

CREATE INDEX idx_assessment_result_landing 
ON AssessmentResult(landingPageId, submittedAt);

CREATE INDEX idx_assessment_result_score 
ON AssessmentResult(score, status);

-- Partitioning by date for large result tables
PARTITION AssessmentResult BY RANGE (YEAR(submittedAt)) (
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p2026 VALUES LESS THAN (2027)
);
```

### API Response Pagination

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  
  factory PaginatedResponse.fromJson(Map json) => 
    PaginatedResponse(
      items: (json['items'] as List).map((i) => T.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['pageSize'],
      hasMore: json['hasMore'],
    );
}

// Usage
Future<void> loadLeads(int pageNumber) async {
  final response = await restClient.get(
    '/api/v1/admin/assessment-leads',
    queryParameters: {
      'page': pageNumber,
      'pageSize': 20,
      'companyId': companyPartyId,
    },
  );
  
  state = state.copyWith(
    leads: [...state.leads, ...response.items],
    hasMore: response.hasMore,
  );
}
```

---

## Testing Strategy

### Unit Tests

```dart
// Test scoring logic
group('AssessmentScoringService', () {
  test('calculates score correctly', () {
    final answers = {
      'q1': 'Yes',
      'q2': 'No',
      'q3': 'Yes',
      'q4': 'Yes',
      'q5': 'No',
      'q6': 'Yes',
      'q7': 'Yes',
      'q8': 'No',
      'q9': 'Yes',
      'q10': 'Yes',
    }; // 7 Yes out of 10
    
    final score = service.calculateScore(answers);
    expect(score, equals(70)); // 7/10 * 100
  });
  
  test('determines correct status for score', () {
    expect(service.determineStatus(75), equals('Hot'));
    expect(service.determineStatus(55), equals('Warm'));
    expect(service.determineStatus(25), equals('Cold'));
  });
});

// Test BLoC state transitions
group('AssessmentBloc', () {
  test('emits correct sequence on contact info submission', () async {
    final bloc = AssessmentBloc();
    
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContactInfoForm>(),
        isA<BestPracticesForm>(),
      ]),
    );
    
    bloc.add(SubmitContactInfoEvent({
      'name': 'John Doe',
      'email': 'john@example.com',
    }));
  });
});
```

### Integration Tests

```dart
group('Assessment Flow', () {
  testWidgets('Complete assessment journey', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    
    // Land on landing page
    expect(find.text('Is Your Business Ready?'), findsOneWidget);
    
    // Tap CTA
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    // Contact info form
    expect(find.byType(TextFormField), findsWidgets);
    
    // Fill form
    await tester.enterText(find.byType(TextFormField).first, 'John');
    await tester.enterText(find.byType(TextFormField).at(1), 'john@test.com');
    
    // Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    
    // Best practices form
    // ... select answers ...
    
    // Results
    expect(find.text('Your Results'), findsOneWidget);
  });
});
```

---

## Deployment Checklist

- [ ] Database migrations applied (LandingPageEntities + AssessmentEntities)
- [ ] Backend services deployed (LandingPageServices + AssessmentServices)
- [ ] Frontend package built and published to pub.dev
- [ ] Admin features integrated into admin package
- [ ] Seed data loaded for sample landing pages
- [ ] Email templates configured for lead notifications
- [ ] Privacy policy lightbox configured
- [ ] Analytics tracking events set up
- [ ] Rate limiting configured for public API endpoints
- [ ] CDN configured for landing page image assets
- [ ] SSL certificates configured
- [ ] Monitoring & alerting set up
- [ ] Documentation updated
- [ ] Team trained on admin workflows
- [ ] QA sign-off completed

---

## Appendix: Code Examples

### Example: Complete Assessment Flow in Code

```dart
// In HomePage
void _handleAssessmentStart() {
  context.read<AssessmentBloc>().add(
    StartAssessmentEvent(landingPageId: widget.landingPageId),
  );
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AssessmentFlow(
        landingPageId: widget.landingPageId,
        onComplete: _handleAssessmentComplete,
      ),
    ),
  );
}

void _handleAssessmentComplete(AssessmentResult result) {
  // Show results
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ResultsFlow(
        result: result,
        onThankYou: _handleThankYou,
      ),
    ),
  );
  
  // Capture lead in background
  context.read<LeadCaptureBloc>().add(
    CaptureLead(result),
  );
}

void _handleThankYou(Lead lead) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Thank you for completing the assessment, ${lead.firstName}!')),
  );
}
```

---

**Document Version:** 1.0  
**Last Updated:** October 23, 2025
