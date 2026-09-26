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

// A learner registers into an organization that published a course, enrolls
// in it from the catalog and studies the lesson. Course authoring is covered
// by the growerp_courses package tests; here the course is set up by API.
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
const academyTestMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ACADEMY_TEST',
  appId: 'academy',
  name: 'Academy Test',
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

GoRouter createAcademyTestRouter() {
  return createStaticAppRouter(
    menuConfig: academyTestMenuConfig,
    appTitle: 'GrowERP Academy',
    dashboard: const CourseViewer(courseId: ''),
    widgetBuilder: (route) => switch (route) {
      '/courses' => const CourseCatalogView(),
      _ => const CourseViewer(courseId: ''),
    },
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // organizations author courses in the admin app; the academy app has no
  // authoring rights (GROWERP_LEARNING only), so the organization registers
  // for admin and the learner for academy
  const adminApplicationId = 'AppAdmin';
  const learnerApplicationId = 'AppAcademy';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('learner enrolls in and studies a course', (tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createAcademyTestRouter(),
      academyTestMenuConfig,
      const [
        UserCompanyLocalizations.delegate,
        CoursesLocalizations.delegate,
      ],
      restClient: restClient,
      applicationId: adminApplicationId,
      clear: true,
      title: 'Academy Learner Test',
      blocProviders: [
        ...getUserCompanyBlocProviders(restClient, adminApplicationId),
        ...getCoursesBlocProviders(restClient),
      ],
    );

    // the organization publishes a course
    await CommonTest.createCompanyAndAdmin(tester);
    await CourseTest.createPublishedCourse(
      restClient,
      title: 'Academy Course',
      lessonContent: 'Academy lesson body text',
    );
    final companyPartyId = CourseTest.currentCompanyPartyId(tester);
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);

    // a learner of that organization takes it
    final learner = await CourseTest.registerLearner(
      restClient,
      companyPartyId,
      learnerApplicationId,
    );
    await CommonTest.login(tester, username: learner);
    await CourseTest.subscribeInCatalog(tester, '/courses');
    await CourseTest.studyFirstLesson(
      tester,
      '/',
      lessonContent: 'Academy lesson body text',
    );

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
  });
}
