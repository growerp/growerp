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
    await CourseTest.addQuizQuestion(
      tester,
      question: 'What does this course test?',
      options: ['The courses', 'Nothing'],
    );
    await CourseTest.addExercise(
      tester,
      title: 'Use it',
      task: 'Describe where you would use this course.',
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

    // --- admin: a participant, assigned the course, changed, unassigned
    await CourseTest.selectParticipants(tester);
    await CourseTest.addParticipant(
      tester,
      firstName: 'Pat',
      lastName: 'Learner',
      email: 'pat${DateTime.now().millisecondsSinceEpoch}@example.com',
    );
    await CourseTest.assignCourse(tester, 'Test Course Updated');
    await CourseTest.updateParticipant(tester, lastName: 'Student');
    await CourseTest.removeCourse(tester, 0);
    await CourseTest.assignCourse(tester, 'Test Course Updated');
    await CourseTest.closeParticipant(tester);
    expect(find.text('Pat Student'), findsOneWidget);
    await CourseTest.selectCourses(tester);

    // --- admin: AI designs the outline, then writes the lessons
    await CourseTest.createCourseWithAi(
      tester,
      title: 'AI Course',
      audience: 'Freelancers',
      curriculum: 'Basics\nNext steps',
    );
    await CourseTest.writeLessonsWithAi(tester);
    await CourseTest.writeQuizzesWithAi(tester);
    await CourseTest.writeExercisesWithAi(tester);
    await CourseTest.checkOutdatedContent(tester);
    await CourseTest.writeSlidesWithAi(tester);
    await CourseTest.makeVideos(tester);
    await CourseTest.makePromoPack(tester);
    await CourseTest.openPdf(tester, 'courseSlidesPdf', 'slidesPdfDialog');
    await CourseTest.openPdf(tester, 'courseWorkbookPdf', 'workbookPdfDialog');
    await CourseTest.translateCourse(tester);
    await CommonTest.tapByKey(tester, 'cancelCourse');

    // --- learner: bought the course on the website, studies
    final learner = await CourseTest.addLearnerWithCourses(restClient, [
      await CourseTest.courseIdByTitle(restClient, 'Test Course Updated'),
    ]);
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    await CommonTest.login(tester, username: learner);

    await CourseTest.checkCatalog(tester, '/catalog', owned: 1);
    await CourseTest.studyFirstLesson(
      tester,
      '/myCourses',
      lessonContent: 'Lesson one body text',
    );
    await CourseTest.askTutor(tester);
    await CourseTest.doExercise(tester, answer: 'In my own freelance work.');
    await CourseTest.openWorkbook(tester);
    // the only lesson is done: the module quiz, then the certificate
    await CourseTest.takeQuiz(tester, answers: [1], expectPassed: false);
    await CourseTest.takeQuiz(tester, answers: [0], expectPassed: true);
    await CourseTest.openCertificate(tester);

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);

    // --- admin: reviews the learner's exercise
    await CommonTest.login(tester);
    await CourseTest.selectCourses(tester);
    await CourseTest.reviewSubmission(tester, 'Test Course Updated', score: 90);
    // the full course as a file, uploaded again as a new draft
    await CourseTest.downloadAndUploadCourse(
      tester,
      'Test Course Updated',
      fileContains: [
        'Module One',
        'Lesson one body text',
        'What does this course test?',
        'Describe where you would use this course.',
      ],
    );
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
  });
}
