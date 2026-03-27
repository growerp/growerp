/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
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

    // Verify we're authenticated (HomeFormAuth key should be present in logout button icon)
    expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);

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
