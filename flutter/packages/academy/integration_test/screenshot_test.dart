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

/*
app: academy
screens:
  - route: /courses      title: "Course catalog"
  - route: /             title: "My Courses"
  - route: /             title: "Lesson"          tap: myCourse0
*/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
import 'package:growerp_courses/src/course/integration_test/course_test.dart';
import 'package:growerp_models/growerp_models.dart' hide CourseMediaList;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// the ACADEMY_DEFAULT seed menu: subscribed courses at the top, then the catalog
const _academyMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ACADEMY_SCREENSHOT',
  appId: 'academy',
  name: 'Academy',
  menuItems: [
    MenuItem(
      title: 'My Courses',
      route: '/',
      widgetName: 'CourseViewer',
      iconName: 'play_circle_outline',
      sequenceNum: 10,
    ),
    MenuItem(
      title: 'Courses',
      route: '/courses',
      widgetName: 'CourseCatalogView',
      iconName: 'school',
      sequenceNum: 20,
    ),
  ],
);

GoRouter createAcademyScreenshotRouter() {
  return createStaticAppRouter(
    menuConfig: _academyMenuConfig,
    appTitle: 'GrowERP Academy',
    dashboard: const CourseViewer(courseId: ''),
    widgetBuilder: (route) => switch (route) {
      '/courses' => const CourseCatalogView(),
      _ => const CourseViewer(courseId: ''),
    },
  );
}

// Demo courses the organization publishes before the learner signs in.
const _courses = [
  (
    title: 'Bookkeeping Basics',
    description: 'Record income and expenses and read your first reports.',
    module: 'Getting started',
    lesson: 'Why bookkeeping matters',
    content:
        'Good bookkeeping tells you at any moment whether your business '
        'makes money. In this lesson you learn the difference between '
        'income, expenses, assets and liabilities, and how every '
        'transaction is recorded twice: once where the money comes from '
        'and once where it goes to.',
  ),
  (
    title: 'Customer Service Excellence',
    description: 'Turn every customer contact into a reason to come back.',
    module: 'The first contact',
    lesson: 'Listening before answering',
    content:
        'Customers remember how you made them feel. Start every '
        'conversation by listening: let the customer finish, repeat the '
        'question in your own words and only then propose a solution.',
  ),
  (
    title: 'Digital Marketing Fundamentals',
    description: 'Reach new customers with a website, email and social media.',
    module: 'Your online presence',
    lesson: 'A website that sells',
    content:
        'Your website is open day and night. Make sure a visitor '
        'understands within five seconds what you offer, for whom, and '
        'what to do next.',
  ),
];

Future<List<String>> _createCourses(RestClient restClient) async {
  Map<String, dynamic> decode(dynamic response) => response is String
      ? jsonDecode(response) as Map<String, dynamic>
      : response as Map<String, dynamic>;
  final courseIds = <String>[];
  for (final course in _courses) {
    final courseId =
        decode(
              await restClient.createCourse(
                data: {
                  'title': course.title,
                  'description': course.description,
                },
              ),
            )['courseId']
            as String;
    final moduleId =
        decode(
              await restClient.createCourseModule(
                data: {'courseId': courseId, 'title': course.module},
              ),
            )['moduleId']
            as String;
    await restClient.createCourseLesson(
      data: {
        'moduleId': moduleId,
        'title': course.lesson,
        'content': course.content,
      },
    );
    await restClient.updateCourse(
      data: {'courseId': courseId, 'status': 'PUBLISHED'},
    );
    courseIds.add(courseId);
  }
  return courseIds;
}

// ---------------------------------------------------------------------------
// Screenshot helper — captures via RenderRepaintBoundary.toImage() and
// writes PNG to <SCREENSHOTS_DIR>/<name>.png on disk.
// ---------------------------------------------------------------------------

// Absolute path injected by run_screenshots.sh; fallback keeps local dev working.
const _screenshotsDir = String.fromEnvironment(
  'SCREENSHOTS_DIR',
  defaultValue: 'screenshots',
);

Future<String> _resolveScreenshotPath(String name) async {
  final preferredDir = Directory(_screenshotsDir);
  try {
    await preferredDir.create(recursive: true);
    return '${preferredDir.path}/$name.png';
  } on FileSystemException catch (e) {
    final fallbackDir = Directory(
      '${Directory.systemTemp.path}/growerp_screenshots/academy',
    );
    await fallbackDir.create(recursive: true);
    // ignore: avoid_print
    print(
      'WARNING: could not create screenshot dir "${preferredDir.path}" '
      '(${e.osError?.message ?? e.message}); using "${fallbackDir.path}"',
    );
    return '${fallbackDir.path}/$name.png';
  }
}

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
  // `.first` in pre-order DFS = the outermost RepaintBoundary (parent before
  // children), which wraps the full viewport.
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final ui.Image image = await boundary.toImage(
    pixelRatio: tester.view.devicePixelRatio,
  );
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  if (bytes == null) {
    // ignore: avoid_print
    print('WARNING: _screenshot("$name") — toByteData returned null, skipping');
    return;
  }
  final outPath = await _resolveScreenshotPath(name);
  // ignore: avoid_print
  print('Writing screenshot → $outPath');
  final file = await File(outPath).create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // organizations author courses in the admin app; the learner uses academy
  const adminApplicationId = 'AppAdmin';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('academy store screenshots', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createAcademyScreenshotRouter(),
      _academyMenuConfig,
      const [UserCompanyLocalizations.delegate, CoursesLocalizations.delegate],
      restClient: restClient,
      applicationId: adminApplicationId,
      clear: true,
      title: 'Academy Screenshots',
      blocProviders: [
        ...getUserCompanyBlocProviders(restClient, adminApplicationId),
        ...getCoursesBlocProviders(restClient),
      ],
    );

    // the organization publishes its courses
    await CommonTest.createCompanyAndAdmin(tester);
    final courseIds = await _createCourses(restClient);
    // a learner bought the first two on the website
    final learner = await CourseTest.addLearnerWithCourses(
      restClient,
      courseIds.take(2).toList(),
    );
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);

    // the learner browses and studies
    await CommonTest.login(tester, username: learner);

    await CommonTest.selectOption(tester, '/courses', 'catalogItem0');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _screenshot(binding, tester, 'catalog');

    await CommonTest.selectOption(tester, '/', 'myCourse0');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _screenshot(binding, tester, 'my_courses');

    await CommonTest.tapByKey(
      tester,
      'myCourse0',
      seconds: CommonTest.waitTime,
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await _screenshot(binding, tester, 'lesson');
  });
}
