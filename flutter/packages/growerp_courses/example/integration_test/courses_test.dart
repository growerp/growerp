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
import 'package:courses_example/router_builder.dart'; // For createDynamicCoursesRouter
import 'package:flutter/material.dart'; // For GlobalKey, NavigatorState
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP Courses integration test', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    const coursesMenuConfig = MenuConfiguration(
      menuConfigurationId: 'COURSES_EXAMPLE',
      appId: 'courses_example',
      name: 'Courses Example Menu',
      menuItems: [
        MenuItem(
          menuItemId: 'COURSES_MAIN',
          title: 'Main',
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 10,
          widgetName: 'CoursesDashboard',
          isActive: true,
        ),
        MenuItem(
          menuItemId: 'COURSES_LIST',
          title: 'Courses',
          route: '/courses',
          iconName: 'school',
          sequenceNum: 20,
          widgetName: 'CourseList',
          isActive: true,
        ),
        MenuItem(
          menuItemId: 'COURSES_MEDIA',
          title: 'Course Media',
          route: '/media',
          iconName: 'auto_awesome',
          sequenceNum: 30,
          widgetName: 'CourseMediaList',
          isActive: true,
        ),
      ],
    );

    final router = createDynamicCoursesRouter([
      coursesMenuConfig,
    ], rootNavigatorKey: GlobalKey<NavigatorState>());

    // Create and seed MenuConfigBloc with the test configuration
    final menuConfigBloc = MenuConfigBloc(restClient, 'courses_example')
      ..add(const MenuConfigUpdateLocal(coursesMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      coursesMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: 'Courses Test',
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Create a test course, module, and lesson
    final courseResponse = await restClient.createCourse(
      data: {
        'title': 'Integration Test Course',
        'description': 'A course for testing',
        'status': 'Active', // Ensure status is explicitly set if required
      },
    );
    final courseId = courseResponse['courseId'];

    final moduleResponse = await restClient.createCourseModule(
      data: {'courseId': courseId, 'title': 'Test Module 1', 'sequenceNum': 1},
    );
    final moduleId = moduleResponse['moduleId'];

    await restClient.createCourseLesson(
      data: {
        'moduleId': moduleId,
        'title': 'Test Lesson 1',
        'content': 'This is the content of the test lesson.',
        'sequenceNum': 1,
      },
    );

    // Check that menu option cards are displayed on the dashboard
    // Use findsAtLeastNWidgets because "Courses" might be in the menu and on the dashboard
    expect(find.text('Courses'), findsAtLeastNWidgets(1));
    expect(find.text('Course Media'), findsAtLeastNWidgets(1));

    // Verify we're authenticated (HomeFormAuth key should be present in logout button icon)
    expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);

    // Navigate to Course List
    await tester.tap(find.text('Courses').last);
    await tester.pumpAndSettle();

    // Verify Course List shows the created course
    expect(find.text('Integration Test Course'), findsOneWidget);

    // Open the course
    await tester.tap(find.text('Integration Test Course'));
    await tester.pumpAndSettle();

    // Select the lesson (it might be automatically selected or we need to tap it in the sidebar)
    // Sidebar usually shows modules/lessons.
    expect(find.text('Test Module 1'), findsOneWidget);
    // Expand module if not expanded (Logic says initiallyExpanded: index == 0, so it should be visible)

    expect(find.text('Test Lesson 1'), findsOneWidget);
    await tester.tap(find.text('Test Lesson 1'));
    await tester.pumpAndSettle();

    // Verify Lesson Content
    expect(find.textContaining('This is the content'), findsOneWidget);

    // Verify "Mark as Complete" button exists
    final markCompleteFinder = find.widgetWithText(
      ElevatedButton,
      'Mark as Complete',
    );
    expect(markCompleteFinder, findsOneWidget);

    // Tap Mark as Complete
    await tester.tap(markCompleteFinder);
    await tester.pumpAndSettle();

    // Verify it changes to "Completed"
    expect(find.widgetWithText(ElevatedButton, 'Completed'), findsOneWidget);

    await CommonTest.logout(tester);
  });
}
