/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: depend_on_referenced_packages
import 'package:courses_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
import 'package:growerp_models/growerp_models.dart' hide CourseMediaList;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP Courses integration test', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createCoursesExampleRouter(),
      coursesMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: 'Courses Test',
      blocProviders: [
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getCoursesBlocProviders(restClient),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Create a test course, module, and lesson
    await restClient.createCourse(
      data: {
        'title': 'Integration Test Course',
        'description': 'A course for testing',
      },
    );

    // Verify we're authenticated (logoutButton is present in static router after auth)
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    // Navigate to Course List
    await tester.tap(find.text('Courses').last);
    await tester.pumpAndSettle();

    // Verify Course List shows the created course
    expect(find.text('Integration Test Course'), findsOneWidget);

    // Open the course dialog (admin edit view)
    await tester.tap(find.text('Integration Test Course'));
    await tester.pumpAndSettle();

    // Verify the course dialog opened with the correct title
    expect(find.byKey(const Key('courseTitle')), findsOneWidget);

    // Dismiss the dialog
    await tester.tapAt(const Offset(10, 10)); // tap outside to dismiss
    await tester.pumpAndSettle();

    await CommonTest.logout(tester);
  });
}
