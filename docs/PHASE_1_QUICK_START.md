# Phase 1 Quick Start Guide - growerp_assessment Package

**Duration:** Weeks 1-2 (10 business days)  
**Deliverable:** Standalone reusable assessment building block package  
**Status:** 🚀 Ready to begin

---

## Pre-Implementation Checklist

Before starting, verify you have:

- [ ] **Moqui Environment**
  - [ ] Moqui development environment running
  - [ ] PostgreSQL database configured
  - [ ] `./gradlew build` working
  - [ ] Can run Moqui tests
  
- [ ] **Flutter Environment**
  - [ ] Flutter SDK installed (latest stable)
  - [ ] Android SDK/iOS SDK configured  
  - [ ] Melos package manager installed
  - [ ] `melos bootstrap` working
  - [ ] `flutter pub global activate build_runner` done
  
- [ ] **GrowERP Knowledge**
  - [ ] Familiar with growerp_core structure
  - [ ] Familiar with growerp_models patterns
  - [ ] Familiar with BLoC pattern
  - [ ] Understand dual-ID strategy (entityId + pseudoId)
  
- [ ] **Repository Access**
  - [ ] Can push to growerp/flutter repository
  - [ ] Can push to growerp/moqui repository
  - [ ] Have appropriate branch permissions

---

## Quick Reference: Key Files

**Main Planning Documents:**
- `IMPLEMENTATION_SEQUENCE.md` - Complete implementation phases
- `Assessment_Landing_Page_Explanation.md` - Complete Phase 12 technical guide
- `GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md` - Architecture rationale

**Recent Documentation (Phase Context):**
- `OWNERPARTYID_REPLACEMENT_SUMMARY.md` - Backend ID strategy (use `ownerPartyId`)
- `GrowERP Extensibility Guide` - Architecture decisions
- `Building Blocks Development Guide` - Package vs app patterns

**Specification Details:**
- See `Assessment_Landing_Page_Explanation.md` for complete implementation
- See `GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md` for architecture overview

---

## Phase 1 Day-by-Day Breakdown

### Week 1: Backend & Models

#### **Days 1-2: Backend Entity Setup**

**Morning (Day 1):**
```
1. Create Moqui component directory structure:
   moqui/runtime/component/growerp/entity/
   moqui/runtime/component/growerp/service/
   moqui/runtime/component/growerp/screen/

2. Create entity definition files:
   - AssessmentEntities.xml (Assessment, AssessmentQuestion, 
     AssessmentQuestionOption, ScoringThreshold)
   - ResultEntities.xml (AssessmentResult)

3. Define entities with required fields:
   - All have: [entityName]Id (system-wide unique primary key)
   - All have: pseudoId (user-facing tenant-unique alternative)
   - All have: ownerPartyId (multi-tenant isolation)
   - All have: createdByUserLogin, createdDate, lastModifiedByUserLogin, lastModifiedDate
```

**Entities to Create:**

```xml
<!-- Assessment -->
assessmentId (PK), pseudoId (unique), ownerPartyId (FK), 
assessmentName, description, status, createdDate

<!-- AssessmentQuestion -->
questionId (PK), pseudoId (unique), assessmentId (FK),
questionSequence, questionType, questionText, questionDescription

<!-- AssessmentQuestionOption -->
optionId (PK), pseudoId (unique), questionId (FK),
optionSequence, optionText, optionScore

<!-- ScoringThreshold -->
thresholdId (PK), pseudoId (unique), assessmentId (FK),
minScore, maxScore, leadStatus (Cold/Warm/Hot)

<!-- AssessmentResult -->
resultId (PK), pseudoId (unique), assessmentId (FK), ownerPartyId (FK),
score, leadStatus, capturedLeadId, createdDate, resultData (JSON)
```

**Afternoon (Day 1):**
```
4. Create database relationships:
   - Assessment 1:N AssessmentQuestion
   - AssessmentQuestion 1:N AssessmentQuestionOption
   - Assessment 1:N ScoringThreshold
   - Assessment 1:N AssessmentResult

5. Create indices for performance:
   - INDEX ON (ownerPartyId, assessmentId)
   - INDEX ON (pseudoId) for fast lookups
   - INDEX ON (createdDate) for sorting
```

**Verification (End of Day 1):**
- [ ] All 5 entity files created
- [ ] All relationships defined
- [ ] Database schema verified
- [ ] Can generate database from entities

**Day 2:**
```
6. Verify in database:
   - Create dev database from entities
   - Check all tables created
   - Check all indices created
   - Check relationships correct

7. Create sample test data:
   - 1 Assessment with pseudoId
   - 3 Questions
   - 9 Options (3 per question)
   - 3 Thresholds (Cold/Warm/Hot)
   - 5 Results (mixed scores)

8. Test database queries:
   - Query by assessmentId (system key)
   - Query by pseudoId (user-facing key)
   - Join Assessment → Questions → Options
   - Verify multi-tenant filtering (ownerPartyId)
```

**Verification (End of Day 2):**
- [ ] All sample data created
- [ ] Query by assessmentId works
- [ ] Query by pseudoId works
- [ ] Multi-tenant filtering works

---

#### **Day 3: Backend Services**

**Morning:**
```
1. Create AssessmentServices.xml with 6 services:
   
   getAssessment(assessmentId or pseudoId, ownerPartyId)
   ├─ Accepts: assessmentId OR pseudoId
   ├─ Filters: WHERE ownerPartyId = ?
   └─ Returns: Assessment + Questions + Options + Thresholds
   
   listAssessments(ownerPartyId, pageNumber, pageSize)
   ├─ Returns: List of Assessments for tenant
   ├─ Includes: Question count, recent results count
   └─ Paging: 20 per page default
   
   createAssessment(assessmentName, description, ownerPartyId, questions)
   ├─ Generate pseudoId (unique per tenant)
   ├─ Create Assessment entity
   ├─ Create Questions entities
   ├─ Generate assessmentId (system-wide unique)
   └─ Returns: New Assessment with all IDs
   
   updateAssessment(assessmentId, assessmentName, description, questions)
   ├─ Update Assessment entity
   ├─ Update/insert/delete Questions as needed
   ├─ Preserve all IDs
   └─ Returns: Updated Assessment
   
   deleteAssessment(assessmentId)
   ├─ Soft delete or hard delete with cascading
   ├─ Decide: Delete results too? (probably keep them)
   └─ Returns: Success/failure
   
   submitAssessment(assessmentId, leadInfo, answers)
   ├─ Validate all answers
   ├─ Calculate score
   ├─ Create AssessmentResult
   ├─ Extract lead info from Step 1
   └─ Returns: Result with score and status
```

**Afternoon:**
```
2. Create ScoringServices.xml:
   
   calculateScore(assessmentId, answers)
   ├─ Load assessment questions
   ├─ Load scoring thresholds
   ├─ Calculate: sum(answer_score * question_weight)
   ├─ Normalize to 0-100 scale
   └─ Returns: Score (0-100)
   
   getThresholds(assessmentId)
   ├─ Query ScoringThreshold table
   ├─ Returns: [{minScore, maxScore, leadStatus}, ...]
   └─ Used by admin to configure scoring
   
   updateThresholds(assessmentId, thresholds)
   ├─ Update ScoringThreshold records
   ├─ Validate no overlaps
   ├─ Validate total coverage 0-100
   └─ Returns: Updated thresholds

3. Implement dual-ID lookup in all services:
   - If parameter starts with "pseudo_": lookup by pseudoId
   - Else: lookup by assessmentId (system key)
   - Always filter by ownerPartyId (multi-tenant)

4. Implement error handling:
   - Assessment not found → return 404
   - Insufficient permissions (ownerPartyId mismatch) → return 403
   - Invalid data → return 400 with details
   - Server error → return 500 with logging
```

**Verification (End of Day 3):**
- [ ] All 6 assessment services created
- [ ] All 3 scoring services created
- [ ] All services accept both ID types
- [ ] Multi-tenant filtering enforced
- [ ] Error handling complete
- [ ] Can call services via REST API

---

#### **Days 4-5: Moqui Testing**

**Day 4:**
```
1. Create integration tests (groovy):
   
   test_createAssessment_success()
   ├─ Create new assessment
   ├─ Verify assessmentId generated
   ├─ Verify pseudoId generated
   ├─ Verify in database
   └─ Assert: ID fields present, ownerPartyId set
   
   test_getAssessment_byAssessmentId()
   ├─ Create assessment
   ├─ Query by assessmentId
   ├─ Assert: Full data returned (questions, options)
   
   test_getAssessment_byPseudoId()
   ├─ Create assessment  
   ├─ Query by pseudoId
   ├─ Assert: Same data as assessmentId query
   
   test_multiTenantIsolation()
   ├─ Create assessment in tenant A (ownerPartyId = A)
   ├─ Try to query from tenant B (ownerPartyId = B)
   ├─ Assert: 403 Forbidden (no data leakage)
   
   test_calculateScore_cold()
   ├─ Submit answers scoring 30%
   ├─ Assert: Cold status returned
   
   test_calculateScore_warm()
   ├─ Submit answers scoring 60%
   ├─ Assert: Warm status returned
   
   test_calculateScore_hot()
   ├─ Submit answers scoring 85%
   ├─ Assert: Hot status returned

2. Run all tests:
   ./gradlew test
```

**Day 5:**
```
3. Load and performance testing:
   
   Load Test:
   ├─ Create 10,000 assessments
   ├─ Create 100,000 questions
   ├─ Create 1,000,000 options
   ├─ Measure query times
   ├─ Assert: < 200ms for single query
   ├─ Assert: < 2s for list(20 per page)
   
   Performance Optimization:
   ├─ Identify slow queries
   ├─ Add indices if needed
   ├─ Add caching if appropriate
   ├─ Re-run tests
   ├─ Document findings

4. API Documentation:
   ├─ Document all endpoints
   ├─ Document request/response formats
   ├─ Document both ID types
   ├─ Document error codes
   ├─ Include curl examples
```

**Verification (End of Week 1, Day 5):**
- [ ] All integration tests passing
- [ ] Load test completed
- [ ] Performance meets targets (<200ms)
- [ ] Multi-tenant isolation verified
- [ ] API documentation complete
- [ ] Ready for Flutter team to integrate

---

### Week 2: Flutter Models & Screens

#### **Days 6-7: Flutter Models & Setup**

**Day 6:**
```
1. Create Flutter package directory:
   flutter/packages/growerp_assessment/
   ├── lib/
   │   ├── growerp_assessment.dart (main export)
   │   └── src/
   │       ├── models/
   │       │   ├── assessment.dart
   │       │   ├── assessment_question.dart
   │       │   ├── assessment_option.dart
   │       │   ├── scoring_threshold.dart
   │       │   └── assessment_result.dart
   │       ├── services/
   │       │   ├── assessment_service.dart
   │       │   └── assessment_client.dart (Retrofit)
   │       ├── blocs/
   │       │   ├── assessment/assessment_bloc.dart
   │       │   ├── assessment/assessment_event.dart
   │       │   └── assessment/assessment_state.dart
   │       ├── screens/
   │       ├── widgets/
   │       └── utils/
   ├── test/
   ├── example/
   │   ├── lib/main.dart
   │   └── integration_test/
   ├── pubspec.yaml
   └── README.md

2. Create pubspec.yaml with dependencies:
   dependencies:
     flutter:
       sdk: flutter
     growerp_core: ^1.9.0
     growerp_models: ^1.9.0
     flutter_bloc: ^8.0.0
     dio: ^5.0.0
     retrofit: ^4.0.0
     equatable: ^2.0.0
   
   dev_dependencies:
     build_runner: ^2.4.0
     retrofit_generator: ^8.0.0

3. Create data models with JSON serialization:
   - Assessment (assessmentId, pseudoId, ownerPartyId, ...)
   - AssessmentQuestion (questionId, pseudoId, ...)
   - AssessmentQuestionOption (optionId, pseudoId, ...)
   - ScoringThreshold (thresholdId, pseudoId, ...)
   - AssessmentResult (resultId, pseudoId, ...)

4. Add @JsonSerializable() to all models
```

**Day 7:**
```
5. Create Retrofit client:
   
   @RestApi(baseUrl: "https://backend/api/")
   abstract class AssessmentClient {
     factory AssessmentClient(Dio dio, {String baseUrl}) = _AssessmentClient;
     
     @GET('/assessment/{idOrPseudo}')
     Future<Assessment> getAssessment(@Path('idOrPseudo') String id);
     
     @GET('/assessments')
     Future<List<Assessment>> listAssessments(
       @Query('pageNumber') int page,
       @Query('pageSize') int size
     );
     
     @POST('/assessment')
     Future<Assessment> createAssessment(@Body Assessment assessment);
     
     @PUT('/assessment/{id}')
     Future<Assessment> updateAssessment(
       @Path('id') String id,
       @Body Assessment assessment
     );
     
     @DELETE('/assessment/{id}')
     Future<void> deleteAssessment(@Path('id') String id);
     
     @POST('/assessment/{id}/submit')
     Future<AssessmentResult> submitAssessment(
       @Path('id') String id,
       @Body AssessmentSubmission submission
     );
   }

6. Run build_runner:
   flutter pub run build_runner build --delete-conflicting-outputs
   
7. Verify all JSON serialization working

8. Create unit tests for models:
   test('Assessment serializes correctly', () {
     final assessment = Assessment(
       assessmentId: 'a123',
       pseudoId: 'pseudo_1',
       ownerPartyId: 'p123',
       // ...
     );
     final json = assessment.toJson();
     final restored = Assessment.fromJson(json);
     expect(restored, equals(assessment));
   });
```

**Verification (End of Days 6-7):**
- [ ] Package structure created
- [ ] All models defined
- [ ] JSON serialization working
- [ ] Retrofit client generated
- [ ] Model tests passing (>90% coverage)

---

#### **Days 8-9: BLoC & Services**

**Day 8:**
```
1. Create AssessmentBloc with events:
   
   abstract class AssessmentEvent extends Equatable {
     const AssessmentEvent();
   }
   
   class FetchAssessmentEvent extends AssessmentEvent {
     final String idOrPseudoId;
     const FetchAssessmentEvent(this.idOrPseudoId);
     @override List<Object> get props => [idOrPseudoId];
   }
   
   class CreateAssessmentEvent extends AssessmentEvent {
     final Assessment assessment;
     const CreateAssessmentEvent(this.assessment);
     @override List<Object> get props => [assessment];
   }
   
   class UpdateAssessmentEvent extends AssessmentEvent {
     final Assessment assessment;
     const UpdateAssessmentEvent(this.assessment);
     @override List<Object> get props => [assessment];
   }
   
   class SubmitAssessmentEvent extends AssessmentEvent {
     final String assessmentId;
     final List<int> answers;
     final String name, email, phone;
     // ...
   }
   
   class DeleteAssessmentEvent extends AssessmentEvent {
     final String assessmentId;
     // ...
   }

2. Create AssessmentState:
   
   abstract class AssessmentState extends Equatable {
     const AssessmentState();
   }
   
   class AssessmentInitial extends AssessmentState {
     @override List<Object> get props => [];
   }
   
   class AssessmentLoading extends AssessmentState {
     @override List<Object> get props => [];
   }
   
   class AssessmentLoaded extends AssessmentState {
     final Assessment assessment;
     const AssessmentLoaded(this.assessment);
     @override List<Object> get props => [assessment];
   }
   
   class AssessmentError extends AssessmentState {
     final String message;
     const AssessmentError(this.message);
     @override List<Object> get props => [message];
   }
   
   class AssessmentSubmitted extends AssessmentState {
     final AssessmentResult result;
     const AssessmentSubmitted(this.result);
     @override List<Object> get props => [result];
   }

3. Create AssessmentBloc class with event handlers:
   
   class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
     final AssessmentService _service;
     
     AssessmentBloc(this._service) : super(AssessmentInitial()) {
       on<FetchAssessmentEvent>(_onFetchAssessment);
       on<CreateAssessmentEvent>(_onCreateAssessment);
       on<SubmitAssessmentEvent>(_onSubmitAssessment);
       // ...
     }
     
     Future<void> _onFetchAssessment(
       FetchAssessmentEvent event,
       Emitter<AssessmentState> emit,
     ) async {
       emit(AssessmentLoading());
       try {
         final assessment = await _service.getAssessment(event.idOrPseudoId);
         emit(AssessmentLoaded(assessment));
       } on DioException catch (e) {
         emit(AssessmentError(e.message));
       }
     }
     
     Future<void> _onSubmitAssessment(
       SubmitAssessmentEvent event,
       Emitter<AssessmentState> emit,
     ) async {
       emit(AssessmentLoading());
       try {
         final result = await _service.submitAssessment(
           event.assessmentId,
           event.answers,
           event.name,
           event.email,
           // ...
         );
         emit(AssessmentSubmitted(result));
       } on DioException catch (e) {
         emit(AssessmentError(e.message));
       }
     }
   }
```

**Day 9:**
```
4. Create AssessmentService (business logic):
   
   class AssessmentService {
     final AssessmentClient _client;
     
     AssessmentService(this._client);
     
     Future<Assessment> getAssessment(String idOrPseudoId) {
       return _client.getAssessment(idOrPseudoId);
     }
     
     Future<AssessmentResult> submitAssessment(
       String assessmentId,
       List<int> answers,
       String name,
       String email,
       String phone,
     ) async {
       // Validate answers
       // Create submission object
       // Call backend API
       // Return result
     }
   }

5. Add caching strategy:
   - Cache assessment for 5 minutes
   - Invalidate on create/update/delete
   - Use BlocProvider for global state

6. Create BLoC unit tests:
   
   test('FetchAssessmentEvent emits AssessmentLoaded', () {
     final assessment = Assessment(...);
     when(mockService.getAssessment(any))
       .thenAnswer((_) async => assessment);
     
     expect(
       assessmentBloc.stream,
       emitsInOrder([
         isA<AssessmentLoading>(),
         isA<AssessmentLoaded>(),
       ]),
     );
     
     assessmentBloc.add(FetchAssessmentEvent('123'));
   });
   
   test('Error emits AssessmentError', () {
     when(mockService.getAssessment(any))
       .thenThrow(DioException(...));
     
     expect(
       assessmentBloc.stream,
       emitsInOrder([
         isA<AssessmentLoading>(),
         isA<AssessmentError>(),
       ]),
     );
     
     assessmentBloc.add(FetchAssessmentEvent('invalid'));
   });
```

**Verification (End of Days 8-9):**
- [ ] AssessmentBloc created with all events
- [ ] AssessmentState hierarchy complete
- [ ] AssessmentService layer created
- [ ] Error handling implemented
- [ ] BLoC tests passing (>90% coverage)
- [ ] Caching strategy working

---

#### **Day 10: Documentation**

**Morning:**
```
1. Create package README.md:
   
   # growerp_assessment
   
   A modular, reusable Flutter package for building assessment/survey 
   flows in GrowERP applications.
   
   ## Features
   - Dynamic question loading
   - Multiple choice, rating, text input options
   - Configurable scoring with thresholds
   - Lead capture integration
   - Multi-tenant support (ownerPartyId isolation)
   - Dual-ID strategy (entityId + pseudoId)
   
   ## Installation
   ```yaml
   dependencies:
     growerp_assessment: ^1.0.0
   ```
   
   ## Quick Start
   ```dart
   // Initialize the bloc
   final assessmentBloc = AssessmentBloc(assessmentService);
   
   // Fetch assessment
   assessmentBloc.add(FetchAssessmentEvent('assessment-id-or-pseudo'));
   
   // Use in widget
   BlocBuilder<AssessmentBloc, AssessmentState>(
     builder: (context, state) {
       if (state is AssessmentLoaded) {
         return AssessmentScreen(assessment: state.assessment);
       }
       return LoadingWidget();
     },
   );
   ```
   
   ## API Documentation
   - See `API.md` for detailed endpoint specifications
   - See `ARCHITECTURE.md` for design decisions
   
   ## Testing
   Run tests:
   ```bash
   flutter test
   ```

2. Create example app (example/lib/main.dart):
   - Demonstrates how to use growerp_assessment
   - Shows all screens in action
   - Shows error handling
   - Shows multi-step flow

3. Create ARCHITECTURE.md:
   - Why this package exists
   - How it separates concerns
   - How to extend it
   - Performance considerations
```

**Afternoon:**
```
4. Create API documentation (API.md):
   - All backend endpoints
   - Request/response formats
   - Error codes
   - Example curl commands
   - Both ID types (entityId, pseudoId)

5. Create CHANGELOG.md:
   ## [1.0.0] - 2025-10-24
   
   ### Added
   - Initial release of growerp_assessment package
   - Assessment model with dual-ID support
   - 6 backend services (get, list, create, update, delete, submit)
   - AssessmentBloc for state management
   - Complete test coverage
   - Example app demonstrating usage
   
   ### Backend
   - AssessmentEntities.xml (5 entities)
   - AssessmentServices.xml (6 services)
   - ScoringServices.xml (3 services)
   - Multi-tenant isolation via ownerPartyId
   - Dual-ID lookup (assessmentId or pseudoId)

6. Verify all documentation is complete and accurate

7. Final checks:
   - All files created
   - All tests passing
   - No lint warnings
   - Can build APK/IPA
```

**Verification (End of Day 10):**
- [ ] README.md complete with features and quick start
- [ ] Example app runs and demonstrates all features
- [ ] ARCHITECTURE.md explains design decisions
- [ ] API.md documents all endpoints
- [ ] CHANGELOG.md updated for v1.0.0
- [ ] Zero lint warnings
- [ ] Package can be published
- [ ] Ready for Phase 2

---

### Days 11-18: Assessment Screens & Integration Tests

**Days 11-12: Step 1-2 Screens**
- Implement lead capture form (name, email, phone, company)
- Implement survey questions screen
- Create form validation and error handling
- Add progress indicators and navigation

**Days 13-14: Step 3 & Result Screen**
- Implement qualification questions (Big 5 + open box)
- Create result confirmation screen
- Allow editing previous answers
- Test complete flow

**Days 15-16: Integration Testing**
- Complete end-to-end flow test
- Mobile device testing
- Performance testing
- Error recovery testing

**Days 17-18: CI/CD & Release**
- Set up GitHub Actions
- Publish to pub.dev (optional)
- Create v1.0.0 release
- Tag repository

---

## Success Metrics

By end of Phase 1, you should have:

```
✅ Backend Complete:
   - 5 entities created with dual IDs
   - 6 assessment services working
   - 3 scoring services working
   - All CRUD operations tested
   - Multi-tenant isolation verified
   - <200ms API response time

✅ Frontend Complete:
   - growerp_assessment package created
   - 5 models with JSON serialization
   - AssessmentBloc with full event handling
   - 3-step assessment screens working
   - Example app demonstrating usage
   - >90% test coverage

✅ Quality:
   - All tests passing
   - Zero lint warnings
   - Documentation complete
   - Performance verified
   - Security checked (multi-tenant isolation)
   - Ready for independent use by other developers

✅ Team Ready:
   - Backend team can hand off to Phase 2
   - Frontend team can hand off to Phase 2
   - Landing page team can begin Phase 2 integration
   - Documentation sufficient for external developers
```

---

## Troubleshooting

**Common Issues & Solutions:**

| Issue | Solution |
|-------|----------|
| Moqui build fails | Run `./gradlew clean build` in moqui/ directory |
| Flutter models don't serialize | Run `flutter pub run build_runner build --delete-conflicting-outputs` |
| BLoC tests fail | Check mock service is returning correct types |
| Multi-tenant test fails | Verify all queries filter by `ownerPartyId` |
| Performance slow | Add database indices, check for N+1 queries |
| CI/CD tests fail | Check all dependencies installed, run locally first |

---

## Next Steps After Phase 1

✅ Phase 1 Complete → Phase 2 Ready

**Immediately after Phase 1:**
1. Code review by 2+ senior developers
2. Security audit for multi-tenant isolation
3. Final performance verification
4. Get go/no-go decision

**Then begin Phase 2:**
- landing_page app creation
- Integration of growerp_assessment
- Landing page screens and admin UI
- Lead capture and backend integration

---

## Communication

**Daily:** 15-min standup
- Blockers?
- On track for Phase 1 completion?
- Any architecture questions?

**Weekly:** 1-hour code review + architecture session
- Code quality check
- Design verification
- Plan for next week

---

## Reference Documents

All detailed specifications in:
- `Assessment_Landing_Page_Explanation.md` (Complete Phase 12 guide)
- `IMPLEMENTATION_SEQUENCE.md` (Phase 1 section)
- `GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md`

---

**Phase 1 Ready to Begin! 🚀**

Questions? Review the main planning documents or reach out to the team lead.

```
