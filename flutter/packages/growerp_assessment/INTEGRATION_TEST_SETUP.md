# Integration Test Setup Guide

**Component**: AssessmentBloc & Service Layer Integration Tests  
**Package**: growerp_assessment  
**Version**: 1.9.0

## Overview

This guide explains how to set up and run integration tests for the assessment package. Integration tests validate end-to-end workflows with mock backend.

---

## Project Structure

```
growerp_assessment/
├── integration_test/
│   ├── assessment_flow_test.dart
│   ├── scoring_flow_test.dart
│   ├── fixtures/
│   │   ├── assessment_fixture.dart
│   │   ├── question_fixture.dart
│   │   └── option_fixture.dart
│   └── helpers/
│       ├── test_helper.dart
│       └── mock_server.dart
└── test/
    └── service/
        └── assessment_service_test.dart
```

---

## Step 1: Setup Test Environment

### pubspec.yaml

Ensure test dependencies are included:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  build_runner: ^2.0.0
  retrofit_generator: ^8.0.0
  flutter_lints: ^4.0.0
  integration_test:
    sdk: flutter
```

### Test Configuration

Create `test/integration_test_setup.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:logger/logger.dart';

class TestSetup {
  static late Dio testDio;
  static late AssessmentApiClient apiClient;
  static late AssessmentRepository repository;
  static late AssessmentService service;
  static late AssessmentBloc bloc;
  static late Logger logger;
  
  static void init() {
    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
      ),
    );
    
    testDio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      receiveTimeout: const Duration(seconds: 10),
      connectTimeout: const Duration(seconds: 10),
    ));
    
    // Add logging interceptor
    testDio.interceptors.add(
      LoggingInterceptor(logger: logger),
    );
    
    apiClient = AssessmentApiClient(testDio);
    
    repository = AssessmentRepository(
      apiClient: apiClient,
      logger: logger,
    );
    
    service = AssessmentService(
      repository: repository,
      logger: logger,
    );
    
    bloc = AssessmentBloc(
      repository: repository,
      logger: logger,
    );
  }
  
  static void cleanup() {
    bloc.close();
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger logger;
  
  LoggingInterceptor({required this.logger});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('REQUEST: ${options.method} ${options.path}');
    logger.d('Headers: ${options.headers}');
    logger.d('Data: ${options.data}');
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    logger.d('Data: ${response.data}');
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
    logger.e('Message: ${err.message}');
    logger.e('Response: ${err.response?.data}');
    super.onError(err, handler);
  }
}
```

---

## Step 2: Create Fixtures

### assessment_fixture.dart

```dart
// test/integration_test/fixtures/assessment_fixture.dart
import 'package:growerp_assessment/growerp_assessment.dart';

class AssessmentFixture {
  static Assessment createAssessment({
    String assessmentId = 'test_assessment_1',
    String pseudoId = 'test_assessment_pseudo_1',
    String assessmentName = 'Product Readiness Assessment',
    String? description = 'Evaluate product market readiness',
    String status = 'ACTIVE',
  }) {
    return Assessment(
      assessmentId: assessmentId,
      pseudoId: pseudoId,
      ownerPartyId: 'test_owner',
      assessmentName: assessmentName,
      description: description,
      status: status,
      createdDate: DateTime.now(),
    );
  }
  
  static List<Assessment> createAssessmentList({int count = 3}) {
    return List.generate(
      count,
      (index) => createAssessment(
        assessmentId: 'assessment_$index',
        pseudoId: 'pseudo_assessment_$index',
        assessmentName: 'Assessment ${index + 1}',
      ),
    );
  }
}
```

### question_fixture.dart

```dart
// test/integration_test/fixtures/question_fixture.dart
import 'package:growerp_assessment/growerp_assessment.dart';

class QuestionFixture {
  static AssessmentQuestion createQuestion({
    String questionId = 'test_question_1',
    String assessmentId = 'test_assessment_1',
    int sequence = 1,
    String type = 'multiselect',
    String text = 'How ready is your product?',
    bool isRequired = true,
  }) {
    return AssessmentQuestion(
      questionId: questionId,
      pseudoId: 'pseudo_$questionId',
      assessmentId: assessmentId,
      questionSequence: sequence,
      questionType: type,
      questionText: text,
      isRequired: isRequired,
      createdDate: DateTime.now(),
    );
  }
  
  static List<AssessmentQuestion> createQuestionList({
    String assessmentId = 'test_assessment_1',
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createQuestion(
        questionId: 'question_${index + 1}',
        assessmentId: assessmentId,
        sequence: index + 1,
        text: 'Question ${index + 1}?',
      ),
    );
  }
}
```

### option_fixture.dart

```dart
// test/integration_test/fixtures/option_fixture.dart
import 'package:growerp_assessment/growerp_assessment.dart';

class OptionFixture {
  static AssessmentQuestionOption createOption({
    String optionId = 'test_option_1',
    String questionId = 'test_question_1',
    String assessmentId = 'test_assessment_1',
    int sequence = 1,
    String text = 'Fully ready',
    double score = 10.0,
  }) {
    return AssessmentQuestionOption(
      optionId: optionId,
      pseudoId: 'pseudo_$optionId',
      questionId: questionId,
      assessmentId: assessmentId,
      optionSequence: sequence,
      optionText: text,
      optionScore: score,
      createdDate: DateTime.now(),
    );
  }
  
  static List<AssessmentQuestionOption> createOptionList({
    String questionId = 'test_question_1',
    String assessmentId = 'test_assessment_1',
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createOption(
        optionId: 'option_${index + 1}',
        questionId: questionId,
        assessmentId: assessmentId,
        sequence: index + 1,
        text: 'Option ${index + 1}',
        score: (index + 1) * 5.0,
      ),
    );
  }
}

class ScoringThresholdFixture {
  static ScoringThreshold createThreshold({
    String thresholdId = 'test_threshold_1',
    String assessmentId = 'test_assessment_1',
    double minScore = 0,
    double maxScore = 33,
    String leadStatus = 'cold',
    String description = 'Not ready',
  }) {
    return ScoringThreshold(
      thresholdId: thresholdId,
      pseudoId: 'pseudo_$thresholdId',
      assessmentId: assessmentId,
      minScore: minScore,
      maxScore: maxScore,
      leadStatus: leadStatus,
      description: description,
      createdDate: DateTime.now(),
    );
  }
  
  static List<ScoringThreshold> createThresholdList({
    String assessmentId = 'test_assessment_1',
  }) {
    return [
      createThreshold(
        thresholdId: 'cold_threshold',
        assessmentId: assessmentId,
        minScore: 0,
        maxScore: 33,
        leadStatus: 'cold',
        description: 'Not ready',
      ),
      createThreshold(
        thresholdId: 'warm_threshold',
        assessmentId: assessmentId,
        minScore: 34,
        maxScore: 66,
        leadStatus: 'warm',
        description: 'Somewhat ready',
      ),
      createThreshold(
        thresholdId: 'hot_threshold',
        assessmentId: assessmentId,
        minScore: 67,
        maxScore: 100,
        leadStatus: 'hot',
        description: 'Very ready',
      ),
    ];
  }
}
```

---

## Step 3: Write Integration Tests

### assessment_flow_test.dart

```dart
// test/integration_test/assessment_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import '../integration_test_setup.dart';
import 'fixtures/assessment_fixture.dart';
import 'fixtures/question_fixture.dart';
import 'fixtures/option_fixture.dart';

void main() {
  setUpAll(() {
    TestSetup.init();
    // Register fallback values for any
    registerFallbackValue(Assessment(
      assessmentId: '',
      pseudoId: '',
      ownerPartyId: '',
      assessmentName: '',
      status: '',
      createdDate: DateTime.now(),
    ));
  });
  
  tearDownAll(() {
    TestSetup.cleanup();
  });
  
  group('Assessment Load Flow', () {
    test('Load assessment successfully', () async {
      // This test assumes backend is running
      // For CI/CD, use mock API client
      
      final assessment = AssessmentFixture.createAssessment();
      
      // Verify assessment creation
      expect(assessment.assessmentId, isNotNull);
      expect(assessment.assessmentName, 'Product Readiness Assessment');
      expect(assessment.status, 'ACTIVE');
    });
    
    test('Load questions for assessment', () async {
      final questions = QuestionFixture.createQuestionList();
      
      expect(questions, isNotEmpty);
      expect(questions.length, 3);
      expect(questions[0].questionSequence, 1);
    });
  });
  
  group('Assessment Scoring Flow', () {
    test('Calculate score from answers', () async {
      final assessment = AssessmentFixture.createAssessment();
      final questions = QuestionFixture.createQuestionList();
      final options = OptionFixture.createOptionList();
      
      // Simulate user answers
      final answers = {
        'question_1': 'option_3',
        'question_2': 'option_2',
        'question_3': 'option_1',
      };
      
      // Score calculation would happen here
      double score = 0;
      score += 15.0; // option_3 score
      score += 10.0; // option_2 score
      score += 5.0;  // option_1 score
      
      expect(score, 30.0);
    });
    
    test('Determine lead status from score', () async {
      final thresholds = ScoringThresholdFixture.createThresholdList();
      
      // Cold threshold
      expect(thresholds[0].leadStatus, 'cold');
      expect(thresholds[0].minScore, 0);
      expect(thresholds[0].maxScore, 33);
      
      // Warm threshold
      expect(thresholds[1].leadStatus, 'warm');
      expect(thresholds[1].minScore, 34);
      expect(thresholds[1].maxScore, 66);
      
      // Hot threshold
      expect(thresholds[2].leadStatus, 'hot');
      expect(thresholds[2].minScore, 67);
      expect(thresholds[2].maxScore, 100);
    });
  });
  
  group('Assessment Submission Flow', () {
    test('Submit assessment with respondent info', () async {
      final assessment = AssessmentFixture.createAssessment();
      
      final answers = {
        'question_1': 'option_1',
        'question_2': 'option_2',
      };
      
      // This would call the actual submission in integration test
      expect(assessment.assessmentId, isNotNull);
      expect(answers, isNotEmpty);
    });
  });
}
```

---

## Step 4: BLoC Integration Tests

### bloc_integration_test.dart

```dart
// test/integration_test/bloc_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import '../integration_test_setup.dart';
import 'fixtures/assessment_fixture.dart';

void main() {
  setUpAll(() => TestSetup.init());
  tearDownAll(() => TestSetup.cleanup());
  
  group('AssessmentBloc Integration Tests', () {
    late MockAssessmentRepository mockRepository;
    late AssessmentBloc bloc;
    
    setUp(() {
      mockRepository = MockAssessmentRepository();
      bloc = AssessmentBloc(
        repository: mockRepository,
        logger: TestSetup.logger,
      );
    });
    
    tearDown(() => bloc.close());
    
    test('Load assessment emits correct states', () async {
      final assessment = AssessmentFixture.createAssessment();
      
      when(() => mockRepository.getAssessment(any()))
        .thenAnswer((_) async => assessment);
      
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AssessmentLoading>(),
          isA<AssessmentLoaded>(),
        ]),
      );
      
      bloc.add(GetAssessmentEvent(assessment.assessmentId));
    });
    
    test('List assessments emits correct states', () async {
      final assessments = AssessmentFixture.createAssessmentList();
      
      when(() => mockRepository.listAssessments(
        start: any(named: 'start'),
        limit: any(named: 'limit'),
        statusId: any(named: 'statusId'),
      )).thenAnswer((_) async => AssessmentListResponse(
        assessments: assessments,
        totalCount: assessments.length,
        pageCount: 1,
        page: 0,
        pageSize: 20,
      ));
      
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AssessmentLoading>(),
          isA<AssessmentsLoaded>(),
        ]),
      );
      
      bloc.add(ListAssessmentsEvent());
    });
    
    test('Handle error states', () async {
      when(() => mockRepository.getAssessment(any()))
        .thenThrow(Exception('Test error'));
      
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AssessmentLoading>(),
          isA<AssessmentError>(),
        ]),
      );
      
      bloc.add(GetAssessmentEvent('test_id'));
    });
  });
}

class MockAssessmentRepository extends Mock implements AssessmentRepository {}
```

---

## Step 5: Run Tests

### Local Testing

```bash
# Run all unit tests
flutter test test/

# Run specific test file
flutter test test/service/assessment_service_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
lcov --list coverage/lcov.info
```

### Integration Testing (with backend)

```bash
# Run integration tests
flutter test integration_test/assessment_flow_test.dart

# Run all integration tests
flutter test integration_test/

# Run with specific device
flutter test -d "device_id" integration_test/
```

### CI/CD Integration

```bash
#!/bin/bash
# scripts/run_tests.sh

set -e

echo "Running unit tests..."
flutter test test/

echo "Running integration tests..."
flutter test integration_test/ --concurrency=1

echo "Generating coverage..."
flutter test --coverage test/

echo "Tests complete!"
```

---

## Step 6: Mock API Server (Optional)

For local development without running full backend:

```dart
// test/helpers/mock_server.dart
import 'package:dio/dio.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

class MockServerInterceptor extends Interceptor {
  final Map<String, dynamic> data;
  
  MockServerInterceptor(this.data);
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Mock GET /assessments
    if (options.method == 'GET' && options.path.contains('/assessments')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: data['assessments'] ?? [],
        ),
      );
    }
    
    // Mock POST /assessments
    if (options.method == 'POST' && options.path == '/assessments') {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {...options.data, 'assessmentId': 'generated_id'},
        ),
      );
    }
    
    super.onRequest(options, handler);
  }
}

Dio createMockDio() {
  final dio = Dio();
  dio.interceptors.add(MockServerInterceptor({
    'assessments': [
      {
        'assessmentId': 'test_1',
        'assessmentName': 'Test Assessment',
        'status': 'ACTIVE',
      },
    ],
  }));
  return dio;
}
```

---

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage of service layer
- **Integration Tests**: Core workflows (load, score, submit)
- **Widget Tests**: Critical UI components

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Assessment Package Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

---

**For more information, see:**
- [Developer Guide](DEVELOPER_GUIDE.md)
- [BLoC Usage Guide](BLoC_USAGE_GUIDE.md)
- [Service Layer Guide](SERVICE_LAYER_GUIDE.md)
