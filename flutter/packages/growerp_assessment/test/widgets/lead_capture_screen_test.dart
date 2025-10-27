import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_assessment/src/screens/lead_capture_screen.dart';

// ignore_for_file: deprecated_member_use

void main() {
  group('LeadCaptureScreen Tests', () {
    late Function(
        {required String name,
        required String email,
        required String company,
        required String phone}) onRespondentDataCollected;
    late VoidCallback onNext;

    setUp(() {
      onRespondentDataCollected = (
          {required String name,
          required String email,
          required String company,
          required String phone}) {};
      onNext = () {};
    });

    testWidgets('Renders all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Displays form labels correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(find.text('Company Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('Shows progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Your Info'), findsOneWidget);
    });

    testWidgets('Validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      // Click Next without filling form
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('Validates email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      // Fill invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Accepts valid form data', (WidgetTester tester) async {
      bool dataCollected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: (
                {required name,
                required email,
                required company,
                required phone}) {
              dataCollected = true;
            },
            onNext: () {},
          ),
        ),
      );

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'ACME Inc');
      await tester.enterText(
          find.byType(TextFormField).at(3), '+1-234-567-8900');

      // Click Next
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(dataCollected, isTrue);
    });

    testWidgets('Cancel button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => LeadCaptureScreen(
                  assessmentId: 'test-assessment',
                  onRespondentDataCollected: onRespondentDataCollected,
                  onNext: onNext,
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Navigator should pop
      expect(find.byType(LeadCaptureScreen), findsNothing);
    });

    testWidgets('Responsive layout on mobile', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);

      await tester.pumpWidget(
        MaterialApp(
          home: LeadCaptureScreen(
            assessmentId: 'test-assessment',
            onRespondentDataCollected: onRespondentDataCollected,
            onNext: onNext,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
