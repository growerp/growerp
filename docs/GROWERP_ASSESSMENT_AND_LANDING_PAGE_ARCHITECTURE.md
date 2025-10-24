# GrowERP Assessment & Landing Page Architecture

**Version:** 1.0  
**Date:** October 23, 2025  
**Status:** Architecture Complete

---

## Executive Summary

Updated architecture for the landing page and assessment system to follow GrowERP building block patterns:

- ✅ **New `growerp_assessment` Package** - Reusable assessment building block (depends on growerp_core + growerp_models)
- ✅ **New `landing_page` App** - Public landing page application (depends on growerp_assessment + growerp_marketing)
- ✅ **Product-Agnostic Design** - Not limited to ERP/sales; any assessment/survey use case
- ✅ **Dual-ID Strategy** - entityId (system-wide) + pseudoId (tenant-unique)
- ✅ **Admin Integration** - Menu-based admin module using growerp_assessment for configuration

---

## Architecture Overview

### Package Hierarchy

```
growerp_models (Lowest)
    ↓
growerp_core (Foundation)
    ↓
growerp_assessment (Building Block - NEW)
    ↓
growerp_marketing (Existing)
    ↓
landing_page (App - NEW)
    ↓
admin (Existing - Extended)
```

### Two Distinct Packages

#### 1. growerp_assessment Package (Building Block)

**Purpose:** Reusable survey/assessment component that can be used in any application

**What It Contains:**
- Assessment configuration models (questions, scoring rules, thresholds)
- Assessment submission and result models
- AssessmentBloc for managing assessment flow
- AssessmentService for CRUD operations
- Assessment scoring service
- All UI screens for assessment flow (3 steps + results)
- Assessment widgets (progress, gauge, etc.)

**What It Does NOT Contain:**
- Landing page content (hero, sections, credibility, etc.)
- Lead capture logic (that's in landing_page app)
- Any assumptions about what the assessment is for

**Dependencies:**
- growerp_core
- growerp_models

**Used By:**
- landing_page app (for assessment flow in landing pages)
- admin package (for assessment configuration)
- Any other app that needs surveys/assessments in the future

#### 2. landing_page App (Public Application)

**Purpose:** Public-facing landing page application that uses growerp_assessment

**What It Contains:**
- Landing page models (page sections, credibility, CTA, etc.)
- Landing page display screens and hero section
- Integration with growerp_assessment for assessment flow
- Lead capture from assessment results
- LeadCaptureService to send leads to marketing

**What It Uses From growerp_assessment:**
- AssessmentBloc (for handling assessment submission)
- Assessment screens and widgets
- AssessmentResult for result data

**Dependencies:**
- growerp_core
- growerp_models
- growerp_assessment (NEW)
- growerp_marketing (for lead integration)

**URL Pattern:**
```
/landingPage/{pseudoId}
Example: /landingPage/page_product_readiness
```

### Admin Package Integration

**Location:** `flutter/packages/admin/lib/src/landing_page/`

**Features:**
- Landing page management (create, edit, delete, preview)
- Assessment configuration via growerp_assessment admin features
- Results dashboard with filtering and export
- Lead status management

**Menu Structure:**
```
Landing Pages
├─ List Pages
├─ Create Page
├─ Manage Assessments (uses growerp_assessment)
└─ Results Dashboard
```

---

## Dual-ID Strategy (Critical)

### Design Pattern

Every backend entity has **two** identification mechanisms:

| ID Type | Example | Scope | User-Facing? | Backend Use |
|---------|---------|-------|--------------|-------------|
| **Entity ID** | `assessmentId: a_abc123xyz` | System-wide unique | ❌ Internal | Primary key, relationships, backend logic |
| **Pseudo ID** | `pseudoId: assess_product_readiness` | Tenant-unique | ✅ Always shown | URLs, API queries, admin UI |

### Benefits

1. **User-Friendly:** pseudoIds are meaningful and tenant-scoped
2. **Flexible:** Backend can use either ID in queries
3. **Secure:** Frontend only sees pseudoIds (URLs safer)
4. **Scalable:** System IDs efficient for relationships and indexing

### Implementation Rules

**All Entities Must Have:**
```dart
final String assessmentId;          // or pageId, surveyId, etc.
final String pseudoId;
```

**All Services Must Support:**
```dart
// Both should work
Future<Assessment> getAssessment(String assessmentId);
Future<Assessment> getAssessment(String pseudoId);
```

**Admin Always Shows:**
```dart
// In dropdown: "assess_product_readiness" (pseudoId)
// In URL: /admin/assessment/assess_product_readiness
// Internally: Convert to assessmentId for backend
```

---

## Backend Architecture

### Moqui Services Organization

**growerp_assessment Services:**
```xml
AssessmentServices.xml
├─ get_Assessment (supports both assessmentId and pseudoId)
├─ list_Assessments
├─ create_Assessment
├─ update_Assessment
├─ delete_Assessment
├─ submit_AssessmentAnswers
└─ calculate_AssessmentScore
```

**landing_page Services:**
```xml
LandingPageServices.xml
├─ get_LandingPage (supports both pageId and pseudoId)
├─ list_LandingPages
├─ create_LandingPage
├─ update_LandingPage
└─ delete_LandingPage

LeadServices.xml
├─ create_AssessmentLead
└─ get_AssessmentLead
```

### Moqui Entities

**growerp_assessment Entities:**
```
Assessment (assessmentId + pseudoId)
├─ AssessmentQuestion
│  └─ AssessmentQuestionOption
├─ ScoringThreshold
└─ AssessmentResult
```

**landing_page Entities:**
```
LandingPage (pageId + pseudoId)
├─ PageSection
├─ CredibilityInfo
│  └─ CredibilityStatistic
├─ PrimaryCTA
└─ AssessmentLead (leadId + pseudoId)
```

### Multi-Tenant Isolation

**Every query filtered by companyPartyId:**
```xml
<where-clause>
  <condition field-name="companyPartyId" operator="equals" value="$companyPartyId"/>
</where-clause>
```

**pseudoId unique per tenant:**
```sql
UNIQUE (companyPartyId, pseudoId)
```

**Foreign keys use system IDs:**
```
LandingPage.assessmentId → Assessment.assessmentId
AssessmentResult.assessmentId → Assessment.assessmentId
```

---

## Frontend Architecture

### growerp_assessment Package Structure

```
growerp_assessment/
├── models/
│   ├── assessment.dart
│   ├── assessment_question.dart
│   ├── assessment_result.dart
│   └── scoring_rule.dart
│
├── services/
│   ├── assessment_service.dart
│   └── assessment_scoring_service.dart
│
├── bloc/
│   ├── assessment_bloc.dart
│   ├── assessment_event.dart
│   └── assessment_state.dart
│
├── screens/
│   ├── assessment_screen.dart
│   ├── step1_info_screen.dart
│   ├── step2_questions_screen.dart
│   ├── step3_qualification_screen.dart
│   └── result_screen.dart
│
├── widgets/
│   ├── assessment_question_widget.dart
│   ├── progress_indicator.dart
│   ├── score_gauge_widget.dart
│   └── result_summary_widget.dart
│
├── get_assessment_bloc_providers.dart
└── growerp_assessment.dart
```

### landing_page App Structure

```
landing_page/
├── models/
│   ├── landing_page.dart
│   ├── page_section.dart
│   ├── credibility_info.dart
│   └── cta.dart
│
├── services/
│   ├── landing_page_service.dart
│   └── lead_capture_service.dart
│
├── bloc/
│   ├── landing_page_bloc.dart
│   ├── lead_capture_bloc.dart
│   └── related event/state classes
│
├── screens/
│   ├── landing_page_screen.dart
│   ├── assessment_flow_screen.dart
│   └── results_screens/ (provided by growerp_assessment)
│
├── widgets/
│   ├── page_hero.dart
│   ├── section_widget.dart
│   ├── credibility_section.dart
│   ├── cta_button.dart
│   └── privacy_policy_link.dart
│
├── get_landing_page_bloc_providers.dart
└── landing_page.dart
```

### Provider Setup

**In growerp_assessment:**
```dart
List<BlocProvider> getAssessmentBlocProviders() => [
  BlocProvider<AssessmentBloc>(
    create: (context) => AssessmentBloc(
      assessmentService: getIt(),
      assessmentScoringService: getIt(),
    ),
  ),
];
```

**In landing_page:**
```dart
List<BlocProvider> getLandingPageBlocProviders() => [
  // Include assessment providers
  ...getAssessmentBlocProviders(),
  
  BlocProvider<LandingPageBloc>(
    create: (context) => LandingPageBloc(
      landingPageService: getIt(),
    ),
  ),
  BlocProvider<LeadCaptureBloc>(
    create: (context) => LeadCaptureBloc(
      leadCaptureService: getIt(),
    ),
  ),
];
```

**In admin:**
```dart
void setupAdminProviders() {
  // Include assessment providers for configuration
  getIt.registerSingleton(getAssessmentBlocProviders());
  
  // Include landing page providers
  getIt.registerSingleton(getLandingPageBlocProviders());
}
```

---

## Data Flow Examples

### Example 1: Create Assessment (Admin)

```
Admin UI (Assessment Builder)
  ↓
  admin_assessment_bloc.dart
    ↓
    AssessmentService.createAssessment()
      ↓
      Backend Service: create_Assessment
        ↓
        AssessmentEntities.xml
          ↓
          Database: INSERT into Assessment
            (assessmentId [auto], pseudoId [user-provided])
```

### Example 2: Submit Assessment (User)

```
landing_page_screen.dart
  ↓
  Uses: AssessmentBloc from growerp_assessment
    ↓
    Step 1: User enters info
    Step 2: User answers questions
    Step 3: User answers qualifications
      ↓
      AssessmentBloc submits to backend
        ↓
        Backend Service: submit_AssessmentAnswers
          ↓
          Moqui Service calculates score
            ↓
            Creates AssessmentResult
              ↓
              Returns resultId + pseudoId + score + status
                ↓
                AssessmentBloc emits AssessmentComplete event
                  ↓
                  landing_page_app routes to results
                    ↓
                    LeadCaptureBloc captures lead
                      ↓
                      Backend Service: create_AssessmentLead
                        ↓
                        Creates Opportunity in Marketing
```

### Example 3: View Results (Admin)

```
admin results_dashboard_page.dart
  ↓
  admin_assessment_bloc.dart loads results
    ↓
    Backend Service: list_AssessmentResults
      (filtered by companyPartyId, optional pageId, statusId)
        ↓
        Returns list with pseudoIds
          ↓
        Admin UI displays pseudoIds in list
          ↓
          User clicks result → detail view
            ↓
            Backend Service: get_AssessmentResult
              (by pseudoId or resultId - both work)
```

---

## Implementation Sequence

### Phase 1: growerp_assessment Package
1. Create package structure
2. Implement models with dual IDs
3. Create backend entities and services
4. Implement AssessmentService with dual-ID support
5. Build AssessmentBloc
6. Create assessment screens and widgets
7. Comprehensive testing

### Phase 2: landing_page App
1. Create app structure
2. Implement landing page models
3. Integrate growerp_assessment
4. Create landing page screens
5. Implement lead capture
6. Backend entities for landing page
7. Integration testing

### Phase 3: Admin Integration
1. Add admin screens for landing pages
2. Integrate assessment builder from growerp_assessment
3. Build results dashboard
4. Test multi-tenant isolation

### Phase 4: Production
1. Performance optimization
2. Security audit
3. Multi-tenant testing
4. Documentation

---

## Key Design Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|-----------|
| Separate growerp_assessment package | Reusability, modularity | More files, coordination needed |
| Dual-ID strategy | User-friendly + secure + scalable | Slight complexity in services |
| Menu-based admin | Consistency with GrowERP pattern | Limited customization |
| Product-agnostic assessment | Future reuse, flexibility | Generic naming conventions |
| BLoC pattern | GrowERP standard, testability | Learning curve for new devs |

---

## Success Metrics

### By Phase 1 (growerp_assessment):
- ✅ Package successfully published
- ✅ Can be imported into other projects
- ✅ All dual-ID queries working
- ✅ 100% test coverage for models/services

### By Phase 2 (landing_page App):
- ✅ Landing pages display correctly
- ✅ Assessment flow completes
- ✅ Scoring calculates accurately
- ✅ Leads captured to marketing

### By Phase 3 (Admin):
- ✅ Admin can create landing pages
- ✅ Admin can configure assessments
- ✅ Results visible in dashboard
- ✅ Multi-tenant isolation verified

### By Phase 4 (Production):
- ✅ <200ms response time
- ✅ 1,000+ concurrent users supported
- ✅ Zero security issues
- ✅ 100% uptime in testing

---

## Comparison: Old vs New Architecture

### Old (Monolithic)
```
configurable_pages/
├─ Models (page + survey + assessment)
├─ Services (page + survey + assessment)
├─ Screens (page + survey + assessment + results)
└─ Can't be reused elsewhere
```

### New (Modular)
```
growerp_assessment/        (Building Block)
├─ Models (assessment only)
├─ Services (assessment only)
├─ Screens (assessment only)
└─ Reusable in any app

landing_page/              (App)
├─ Models (landing page only)
├─ Services (landing page + lead capture)
├─ Screens (landing page + results routing)
└─ Uses growerp_assessment package
```

### Benefits

- ✅ **growerp_assessment** can be reused in marketing app, support app, any future app
- ✅ **landing_page** is cleaner, focused only on page content
- ✅ **Admin** has separation of concerns (assessments vs pages)
- ✅ **Testing** easier with smaller, focused packages
- ✅ **Maintenance** simplified with clear boundaries

---

## Next Steps

1. Review this architecture with team
2. Update implementation plan with this structure
3. Create growerp_assessment package structure
4. Implement Phase 1 (assessment package)
5. Implement Phase 2 (landing_page app)
6. Continue with phases 3-4

---

## Questions & Clarifications

**Q: Can growerp_assessment be used standalone?**  
A: Yes! It's a complete assessment/survey package that can be used in any app.

**Q: How is lead capture different between assessment and landing page?**  
A: growerp_assessment focuses on scoring. landing_page handles lead creation when assessment completes on a landing page.

**Q: Can I use different assessment in different landing pages?**  
A: Yes! Each landing page references an assessmentId. You can reuse assessments or create new ones.

**Q: Is the admin module part of admin package?**  
A: Yes. It adds a "Landing Pages" section to admin menu, which manages both landing pages and assessments.

**Q: What about frontend rendering differences between assessment types?**  
A: growerp_assessment is generic. landing_page can customize how results are displayed.

---

**Document Version:** 1.0  
**Last Updated:** October 23, 2025  
**Status:** Architecture Final - Ready for Implementation
