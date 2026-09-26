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
import 'package:growerp_courses/src/course/integration_test/course_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP Courses: author a course, learner takes it', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createCoursesExampleRouter(),
      coursesMenuConfig,
      const [
        UserCompanyLocalizations.delegate,
        ...CoursesLocalizations.localizationsDelegates,
      ],
      restClient: restClient,
      clear: true,
      title: 'Courses Test',
      blocProviders: [
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getCoursesBlocProviders(restClient),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // --- admin: author a paid course, publish it, delete a draft
    await CourseTest.selectCourses(tester);
    await CourseTest.addCourse(
      tester,
      title: 'Test Course',
      description: 'A course for testing',
      price: '49.00',
    );
    await CourseTest.openCourse(tester, 'Test Course');
    await CourseTest.addModule(tester, 'Module One');
    await CourseTest.addLesson(
      tester,
      title: 'Lesson One',
      content: 'Lesson one body text',
    );
    await CourseTest.updateCourse(
      tester,
      title: 'Test Course Updated',
      status: 'Published',
    );
    expect(find.text('Test Course Updated'), findsWidgets);
    expect(find.text('Published'), findsWidgets);
    await CourseTest.previewCourse(
      tester,
      'Test Course Updated',
      lessonContent: 'Lesson one body text',
    );

    await CourseTest.addCourse(tester, title: 'Draft To Delete');
    await CourseTest.deleteCourse(tester, 'Draft To Delete');

    // --- learner: registers into this company, pays, studies
    final companyPartyId = CourseTest.currentCompanyPartyId(tester);
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    final learner = await CourseTest.registerLearner(
      restClient,
      companyPartyId,
      'AppAcademy',
    );
    await CommonTest.login(tester, username: learner);

    await CourseTest.subscribeInCatalog(tester, '/catalog');
    await CourseTest.studyFirstLesson(
      tester,
      '/myCourses',
      lessonContent: 'Lesson one body text',
    );

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
  });
}
