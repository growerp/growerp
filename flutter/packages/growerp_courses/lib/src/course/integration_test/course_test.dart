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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Course authoring (admin) and learning (customer) steps for integration tests.
class CourseTest {
  // ---------------------------------------------------------------- authoring

  static Future<void> selectCourses(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/courses', 'addNew');
  }

  /// Adds a course from the list; new courses start as draft.
  static Future<void> addCourse(
    WidgetTester tester, {
    required String title,
    String? description,
    String? price,
  }) async {
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.enterText(tester, 'courseTitle', title);
    if (description != null) {
      await CommonTest.enterText(tester, 'courseDescription', description);
    }
    if (price != null) {
      await CommonTest.dragUntil(tester, key: 'coursePrice');
      await CommonTest.enterText(tester, 'coursePrice', price);
    }
    await CommonTest.dragUntil(tester, key: 'saveCourse');
    await CommonTest.tapByKey(
      tester,
      'saveCourse',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    expect(find.text(title), findsWidgets);
  }

  /// Opens the edit dialog of a course by tapping its row.
  static Future<void> openCourse(WidgetTester tester, String title) async {
    await CommonTest.tapByText(tester, title);
    await CommonTest.checkWidgetKey(tester, 'courseTitle');
  }

  static Future<void> addModule(WidgetTester tester, String title) async {
    await CommonTest.dragUntil(tester, key: 'addModule');
    await CommonTest.tapByKey(tester, 'addModule');
    await CommonTest.enterText(tester, 'moduleTitle', title);
    await CommonTest.tapByKey(
      tester,
      'saveModule',
      seconds: CommonTest.waitTime,
    );
    // the dialog shows the course reloaded by the bloc, with the new module
    await CommonTest.dragUntil(tester, key: 'module0');
    expect(find.text(title), findsOneWidget);
  }

  static Future<void> addLesson(
    WidgetTester tester, {
    int moduleIndex = 0,
    required String title,
    required String content,
  }) async {
    await CommonTest.dragUntil(tester, key: 'module$moduleIndex');
    if (!CommonTest.hasKey('addLesson$moduleIndex')) {
      await CommonTest.tapByKey(tester, 'module$moduleIndex'); // expand
    }
    await CommonTest.dragUntil(tester, key: 'addLesson$moduleIndex');
    await CommonTest.tapByKey(tester, 'addLesson$moduleIndex');
    await CommonTest.enterText(tester, 'lessonTitle', title);
    await CommonTest.enterText(tester, 'lessonContent', content);
    await CommonTest.tapByKey(
      tester,
      'saveLesson',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.dragUntil(tester, key: 'module$moduleIndex');
    if (!tester.any(find.text(title))) {
      await CommonTest.tapByKey(tester, 'module$moduleIndex'); // expand
    }
    expect(find.text(title), findsOneWidget);
  }

  /// Saves the open course dialog, optionally with a new title and status.
  static Future<void> updateCourse(
    WidgetTester tester, {
    String? title,
    String? status, // 'Draft', 'Published' or 'Archived'
  }) async {
    if (title != null) {
      await CommonTest.enterText(tester, 'courseTitle', title);
    }
    if (status != null) {
      await CommonTest.dragUntil(tester, key: 'courseStatus');
      await CommonTest.enterDropDown(tester, 'courseStatus', status);
    }
    await CommonTest.dragUntil(tester, key: 'saveCourse');
    await CommonTest.tapByKey(
      tester,
      'saveCourse',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// Pumps (no settle: the AI progress bar animates) until [finder] shows.
  static Future<void> _pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int seconds = 90,
  }) async {
    for (int i = 0; i < seconds * 2 && !tester.any(finder); i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.any(finder), true, reason: 'not shown after ${seconds}s');
    await tester.pumpAndSettle();
  }

  /// Creates a course with the AI wizard. The backend runs in test mode in
  /// CI and returns a canned outline: 2 modules, the first with 2 lessons.
  /// Ends in the course dialog of the new draft course.
  static Future<void> createCourseWithAi(
    WidgetTester tester, {
    required String title,
    String? audience,
    String? curriculum,
  }) async {
    await CommonTest.tapByKey(tester, 'addNewAi');
    await CommonTest.enterText(tester, 'aiCourseTitle', title);
    if (audience != null) {
      await CommonTest.enterText(tester, 'aiCourseAudience', audience);
    }
    if (curriculum != null) {
      await CommonTest.enterText(tester, 'aiCourseCurriculum', curriculum);
    }
    await CommonTest.dragUntil(tester, key: 'aiCourseGenerate');
    await CommonTest.tapByKey(tester, 'aiCourseGenerate', settle: false);
    await _pumpUntil(tester, find.byKey(const Key('courseTitle')));
    await CommonTest.dragUntil(tester, key: 'module0');
    expect(find.byKey(const Key('module1')), findsOneWidget);
  }

  /// Writes all lessons of the open course with AI and waits until done.
  static Future<void> writeLessonsWithAi(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'aiWriteLessons');
    await CommonTest.tapByKey(tester, 'aiWriteLessons');
    await CommonTest.tapByKey(tester, 'aiWriteConfirm', settle: false);
    // the banner shows while the job runs, the snackbar when it is done
    // test mode answers at once; with a real AI every lesson takes seconds
    await _pumpUntil(tester, find.textContaining('written'), seconds: 600);
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// Adds a quiz question to a module of the open course dialog; the first
  /// option is the correct one.
  static Future<void> addQuizQuestion(
    WidgetTester tester, {
    int moduleIndex = 0,
    required String question,
    required List<String> options,
  }) async {
    await CommonTest.dragUntil(tester, key: 'module$moduleIndex');
    if (!CommonTest.hasKey('moduleQuiz$moduleIndex')) {
      await CommonTest.tapByKey(tester, 'module$moduleIndex'); // expand
    }
    await CommonTest.dragUntil(tester, key: 'moduleQuiz$moduleIndex');
    await CommonTest.tapByKey(tester, 'moduleQuiz$moduleIndex');
    await CommonTest.tapByKey(tester, 'addQuestion');
    await CommonTest.enterText(tester, 'questionText', question);
    for (var i = 0; i < options.length; i++) {
      await CommonTest.enterText(tester, 'questionOption$i', options[i]);
    }
    await CommonTest.tapByKey(
      tester,
      'saveQuestion',
      seconds: CommonTest.waitTime,
    );
    expect(find.text(question), findsOneWidget);
    await CommonTest.tapByKey(tester, 'closeQuiz');
    expect(find.textContaining('Quiz: 1 questions'), findsOneWidget);
  }

  /// Lets the AI write the quiz of every module of the open course dialog.
  static Future<void> writeQuizzesWithAi(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'aiWriteQuizzes');
    await CommonTest.tapByKey(tester, 'aiWriteQuizzes');
    await CommonTest.tapByKey(tester, 'aiQuizConfirm', settle: false);
    await _pumpUntil(
      tester,
      find.textContaining('quiz questions written'),
      seconds: 300,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.dragUntil(tester, key: 'module0');
    if (!CommonTest.hasKey('moduleQuiz0')) {
      await CommonTest.tapByKey(tester, 'module0'); // expand
    }
    await CommonTest.dragUntil(tester, key: 'moduleQuiz0');
    expect(find.textContaining('Quiz: 5 questions'), findsWidgets);
  }

  /// Lets the AI make the slides of every module of the open course dialog.
  static Future<void> writeSlidesWithAi(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'aiWriteSlides');
    await CommonTest.tapByKey(tester, 'aiWriteSlides');
    await CommonTest.tapByKey(tester, 'aiSlidesConfirm', settle: false);
    await _pumpUntil(tester, find.textContaining('slides made'), seconds: 300);
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.dragUntil(tester, key: 'moduleSlides0');
    expect(find.textContaining(RegExp(r'Slides: [1-9]')), findsWidgets);
  }

  /// Makes the videos of all modules from their slides and opens the first.
  static Future<void> makeVideos(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'aiWriteVideos');
    await CommonTest.tapByKey(tester, 'aiWriteVideos');
    await CommonTest.tapByKey(tester, 'aiVideoConfirm', settle: false);
    await _pumpUntil(
      tester,
      find.textContaining(RegExp(r'videos? made')),
      seconds: 600,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.dragUntil(tester, key: 'moduleVideo0');
    expect(find.text('Video: ready'), findsWidgets);
    await CommonTest.tapByKey(
      tester,
      'moduleVideo0',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.checkWidgetKey(tester, 'courseVideoDialog');
    Navigator.of(
      tester.element(find.byKey(const Key('courseVideoDialog'))),
    ).pop();
    await tester.pumpAndSettle();
  }

  /// Opens a pdf preview dialog with the button [buttonKey], checks it shows
  /// and closes it.
  static Future<void> openPdf(
    WidgetTester tester,
    String buttonKey,
    String dialogKey,
  ) async {
    await CommonTest.dragUntil(tester, key: buttonKey);
    await CommonTest.tapByKey(tester, buttonKey, seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, dialogKey);
    Navigator.of(tester.element(find.byKey(Key(dialogKey)))).pop();
    await tester.pumpAndSettle();
  }

  /// Learner in the course viewer: the workbook is in the outline, which is
  /// its own tab on a phone.
  static Future<void> openWorkbook(WidgetTester tester) async {
    if (!tester.any(find.byKey(const Key('courseWorkbook')))) {
      await CommonTest.tapByText(tester, 'Outline');
    }
    await openPdf(tester, 'courseWorkbook', 'workbookPdfDialog');
    if (tester.any(find.text('Content'))) {
      await CommonTest.tapByText(tester, 'Content');
    }
  }

  /// Learner, after the last lesson of the first module: takes its quiz
  /// answering [answers] (option index per question) and closes it.
  static Future<void> takeQuiz(
    WidgetTester tester, {
    required List<int> answers,
    required bool expectPassed,
  }) async {
    await CommonTest.dragUntil(tester, key: 'takeQuiz');
    await CommonTest.tapByKey(tester, 'takeQuiz', seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, 'CourseQuizScreen');
    for (var q = 0; q < answers.length; q++) {
      await CommonTest.dragUntil(tester, key: 'quizOption${q}_${answers[q]}');
      await CommonTest.tapByKey(tester, 'quizOption${q}_${answers[q]}');
    }
    await CommonTest.dragUntil(tester, key: 'quizSubmit');
    await CommonTest.tapByKey(
      tester,
      'quizSubmit',
      seconds: CommonTest.waitTime,
    );
    expect(find.text(expectPassed ? 'Passed!' : '0%'), findsOneWidget);
    await CommonTest.dragUntil(tester, key: 'quizClose');
    await CommonTest.tapByKey(
      tester,
      'quizClose',
      seconds: CommonTest.waitTime,
    );
  }

  /// Learner with the course completed: opens the certificate and closes it.
  static Future<void> openCertificate(WidgetTester tester) async {
    await CommonTest.dragUntil(tester, key: 'courseCertificate');
    await CommonTest.tapByKey(
      tester,
      'courseCertificate',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.checkWidgetKey(tester, 'courseCertificateDialog');
    Navigator.of(
      tester.element(find.byKey(const Key('courseCertificateDialog'))),
    ).pop();
    await tester.pumpAndSettle();
  }

  /// Deletes the course with this title after confirming.
  static Future<void> deleteCourse(WidgetTester tester, String title) async {
    await openCourse(tester, title);
    await CommonTest.dragUntil(tester, key: 'deleteCourse');
    await CommonTest.tapByKey(tester, 'deleteCourse');
    await CommonTest.tapByText(tester, 'Delete');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.text(title), findsNothing);
  }

  /// Publishes a course through the edit dialog.
  static Future<void> publishCourse(WidgetTester tester, String title) async {
    await openCourse(tester, title);
    await updateCourse(tester, status: 'Published');
  }

  /// Opens the course from the list, previews it as a learner sees it and
  /// checks the lesson text is shown (staff see drafts too).
  static Future<void> previewCourse(
    WidgetTester tester,
    String title, {
    required String lessonContent,
  }) async {
    await openCourse(tester, title);
    await CommonTest.tapByKey(
      tester,
      'previewCourse',
      seconds: CommonTest.waitTime,
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.textContaining(lessonContent), findsWidgets);
    await tester.pageBack(); // back to the course dialog
    await tester.pumpAndSettle();
    await CommonTest.dragUntil(tester, key: 'cancelCourse');
    await CommonTest.tapByKey(tester, 'cancelCourse'); // close the dialog
    expect(find.byKey(const Key('courseTitle')), findsNothing);
  }

  /// Creates and publishes a course with one module and lesson through the
  /// API, as the logged in admin: the setup for learner-only tests.
  static Future<String> createPublishedCourse(
    RestClient restClient, {
    required String title,
    required String lessonContent,
  }) async {
    Map<String, dynamic> decode(dynamic response) => response is String
        ? jsonDecode(response) as Map<String, dynamic>
        : response as Map<String, dynamic>;
    final courseId =
        decode(
              await restClient.createCourse(data: {'title': title}),
            )['courseId']
            as String;
    final moduleId =
        decode(
              await restClient.createCourseModule(
                data: {'courseId': courseId, 'title': 'Module One'},
              ),
            )['moduleId']
            as String;
    await restClient.createCourseLesson(
      data: {
        'moduleId': moduleId,
        'title': 'Lesson One',
        'content': lessonContent,
      },
    );
    await restClient.updateCourse(
      data: {'courseId': courseId, 'status': 'PUBLISHED'},
    );
    return courseId;
  }

  // ----------------------------------------------------------------- learning

  /// The company of the logged in admin: learners register into it.
  static String currentCompanyPartyId(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).first);
    return context.read<AuthBloc>().state.authenticate!.company!.partyId!;
  }

  /// Registers a learner (Customer, outside user) of an existing company, as
  /// the academy app does when started with ?companyPartyId=. Returns the email.
  static Future<String> registerLearner(
    RestClient restClient,
    String companyPartyId,
    String applicationId,
  ) async {
    final email = 'learner${DateTime.now().millisecondsSinceEpoch}@example.com';
    await restClient.register(
      applicationId: applicationId,
      firstName: 'Lea',
      lastName: 'Rner',
      email: email,
      companyPartyId: companyPartyId,
      newPassword: 'qqqqqq9!',
    );
    return email;
  }

  /// Subscribes from the catalog; paid courses use the test card the payment
  /// dialog pre-fills in debug builds.
  static Future<void> subscribeInCatalog(
    WidgetTester tester,
    String route, {
    int index = 0,
  }) async {
    await CommonTest.selectOption(tester, route, 'catalogItem$index');
    expect(find.text('Subscribed'), findsNothing);
    await CommonTest.tapByKey(tester, 'catalogItem$index');
    await CommonTest.tapByKey(
      tester,
      'subscribe',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.text('Subscribed'), findsOneWidget);
  }

  /// Opens the first subscribed course, checks the lesson text is there and
  /// marks the lesson complete.
  static Future<void> studyFirstLesson(
    WidgetTester tester,
    String route, {
    required String lessonContent,
  }) async {
    await CommonTest.selectOption(tester, route, 'myCourse0');
    await CommonTest.tapByKey(
      tester,
      'myCourse0',
      seconds: CommonTest.waitTime,
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.textContaining(lessonContent), findsWidgets);
    await CommonTest.dragUntil(tester, key: 'completeLesson');
    await CommonTest.tapByKey(
      tester,
      'completeLesson',
      seconds: CommonTest.waitTime,
    );
    expect(find.text('Completed'), findsOneWidget);
  }
}
