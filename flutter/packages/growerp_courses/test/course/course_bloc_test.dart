import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CourseState> courseState(
  CourseBlocStatus status, {
  String? message,
}) {
  var m = isA<CourseState>().having((s) => s.status, 'status', status);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

Iterable<String?> ids(CourseState s) => s.courses.map((c) => c.courseId);

void main() {
  late MockRestClient restClient;

  final flutter = Course(courseId: 'C1', title: 'Flutter');
  final dart = Course(courseId: 'C2', title: 'Dart');
  final withModules = Course(
    courseId: 'C1',
    title: 'Flutter',
    modules: [CourseModule(moduleId: 'M1', title: 'Basics')],
  );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() => restClient = MockRestClient());

  CourseBloc build() => CourseBloc(restClient: restClient);

  void stubDetail() => when(
    () => restClient.getCourse(courseId: 'C1'),
  ).thenAnswer((_) async => courseJson(withModules));

  group('CourseFetch', () {
    blocTest<CourseBloc, CourseState>(
      'CourseFetch_refresh_listsCoursesFromStart',
      setUp: () => when(
        () => restClient.listCourses(start: 0, limit: 20),
      ).thenAnswer((_) async => Courses(courses: [flutter, dart])),
      build: build,
      act: (bloc) => bloc.add(const CourseFetch(refresh: true)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success)
            .having(ids, 'ids', ['C1', 'C2'])
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseFetch_catalog_usesLearnerCatalog',
      setUp: () => when(
        () => restClient.listCourseCatalog(start: 0, limit: 20),
      ).thenAnswer((_) async => Courses(courses: [flutter])),
      build: build,
      act: (bloc) => bloc.add(const CourseFetch(refresh: true, catalog: true)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success).having(ids, 'ids', ['C1']),
      ],
      verify: (_) => verifyNever(
        () => restClient.listCourses(
          start: any(named: 'start'),
          limit: any(named: 'limit'),
        ),
      ),
    );

    blocTest<CourseBloc, CourseState>(
      'CourseFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.listCourses(start: 1, limit: 20),
      ).thenAnswer((_) async => Courses(courses: [dart])),
      build: build,
      seed: () => CourseState(courses: [flutter]),
      act: (bloc) => bloc.add(const CourseFetch()),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success).having(ids, 'ids', ['C1', 'C2']),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseFetch_reachedMaxWithoutRefresh_doesNothing',
      build: build,
      seed: () => CourseState(courses: [flutter], hasReachedMax: true),
      act: (bloc) => bloc.add(const CourseFetch()),
      expect: () => <CourseState>[],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.listCourses(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const CourseFetch(refresh: true)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.failure),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseSearchChanged_threeChars_fetchesWithFilter',
      setUp: () => when(
        () => restClient.listCourses(filter: 'Flu', start: 0, limit: 20),
      ).thenAnswer((_) async => Courses(courses: [flutter])),
      build: build,
      act: (bloc) => bloc.add(const CourseSearchChanged(searchString: 'Flu')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success).having(ids, 'ids', ['C1']),
      ],
    );
  });

  group('CourseGetDetail', () {
    blocTest<CourseBloc, CourseState>(
      'CourseGetDetail_jsonStringBody_setsSelectedCourseWithModules',
      setUp: stubDetail,
      build: build,
      act: (bloc) => bloc.add(const CourseGetDetail('C1')),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success).having(
          (s) => s.selectedCourse?.modules?.single.title,
          'module',
          'Basics',
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseGetDetail_emptyId_failsWithoutBackend',
      build: build,
      act: (bloc) => bloc.add(const CourseGetDetail('')),
      expect: () => [
        courseState(CourseBlocStatus.failure, message: 'courseIdRequired'),
      ],
      verify: (_) => verifyZeroInteractions(restClient),
    );
  });

  group('CourseCreate / Update / Delete', () {
    blocTest<CourseBloc, CourseState>(
      'CourseCreate_course_takesIdsFromResponseAndInsertsFirst',
      setUp: () => when(() => restClient.createCourse(data: any(named: 'data')))
          .thenAnswer(
            (_) async => jsonEncode({
              'courseId': 'C3',
              'pseudoId': 'c3',
              'productId': 'P3',
            }),
          ),
      build: build,
      seed: () => CourseState(courses: [flutter]),
      act: (bloc) => bloc.add(CourseCreate(Course(title: 'Kotlin'))),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success, message: 'courseCreated')
            .having(ids, 'ids', ['C3', 'C1'])
            .having((s) => s.courses.first.productId, 'productId', 'P3'),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseUpdate_course_replacesAndSelectsIt',
      setUp: () => when(
        () => restClient.updateCourse(data: any(named: 'data')),
      ).thenAnswer((_) async => '{}'),
      build: build,
      seed: () => CourseState(courses: [flutter, dart]),
      act: (bloc) =>
          bloc.add(CourseUpdate(Course(courseId: 'C2', title: 'Dart 3'))),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.success, message: 'courseUpdated')
            .having((s) => s.courses.map((c) => c.title), 'titles', [
              'Flutter',
              'Dart 3',
            ])
            .having((s) => s.selectedCourse?.title, 'selected', 'Dart 3'),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseDelete_course_removesIt',
      setUp: () => when(
        () => restClient.deleteCourse(courseId: 'C1'),
      ).thenAnswer((_) async => '{}'),
      build: build,
      seed: () => CourseState(courses: [flutter, dart]),
      act: (bloc) => bloc.add(CourseDelete(flutter)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(
          CourseBlocStatus.success,
          message: 'courseDeleted',
        ).having(ids, 'ids', ['C2']),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCourse(courseId: 'C1'),
      ).thenThrow(dioError('Has learners')),
      build: build,
      seed: () => CourseState(courses: [flutter]),
      act: (bloc) => bloc.add(CourseDelete(flutter)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.failure),
      ],
    );
  });

  group('course content changes reload the detail', () {
    final module = CourseModule(moduleId: 'M1', title: 'Basics');
    final lesson = CourseLesson(lessonId: 'L1', title: 'Widgets');

    blocTest<CourseBloc, CourseState>(
      'CourseModuleCreate_module_sendsCourseIdThenReloadsDetail',
      setUp: () {
        when(
          () => restClient.createCourseModule(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}');
        stubDetail();
      },
      build: build,
      act: (bloc) => bloc.add(
        CourseModuleCreate(
          courseId: 'C1',
          module: CourseModule(title: 'Basics'),
        ),
      ),
      verify: (bloc) {
        final data =
            verify(
                  () => restClient.createCourseModule(
                    data: captureAny(named: 'data'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(data['courseId'], 'C1');
        expect(data['title'], 'Basics');
        expect(bloc.state.selectedCourse?.modules, hasLength(1));
      },
    );

    // Every edit of a selected course follows the same pattern: one REST
    // call, then CourseGetDetail of the selected course.
    final edits = <String, (CourseEvent, void Function(MockRestClient))>{
      'CourseModuleUpdate': (
        CourseModuleUpdate(module),
        (r) => when(
          () => r.updateCourseModule(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseModuleDelete': (
        CourseModuleDelete(module),
        (r) => when(
          () => r.deleteCourseModule(moduleId: 'M1'),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseLessonCreate': (
        CourseLessonCreate(
          moduleId: 'M1',
          lesson: CourseLesson(title: 'x'),
        ),
        (r) => when(
          () => r.createCourseLesson(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseLessonUpdate': (
        CourseLessonUpdate(lesson),
        (r) => when(
          () => r.updateCourseLesson(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseLessonDelete': (
        CourseLessonDelete(lesson),
        (r) => when(
          () => r.deleteCourseLesson(lessonId: 'L1'),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseModuleSlidesSave': (
        CourseModuleSlidesSave('M1', [CourseSlide(title: 'Intro')]),
        (r) => when(
          () => r.updateCourseModule(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseQuizQuestionSave new': (
        CourseQuizQuestionSave(CourseQuizQuestion(question: 'Why?')),
        (r) => when(
          () => r.createCourseQuizQuestion(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseQuizQuestionSave existing': (
        CourseQuizQuestionSave(
          CourseQuizQuestion(questionId: 'Q1', question: 'Why?'),
        ),
        (r) => when(
          () => r.updateCourseQuizQuestion(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseQuizQuestionDelete': (
        const CourseQuizQuestionDelete('Q1'),
        (r) => when(
          () => r.deleteCourseQuizQuestion(questionId: 'Q1'),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseExerciseSave new': (
        CourseExerciseSave(CourseExercise(title: 'Build it')),
        (r) => when(
          () => r.createCourseExercise(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseExerciseSave existing': (
        CourseExerciseSave(CourseExercise(exerciseId: 'E1', title: 'Build')),
        (r) => when(
          () => r.updateCourseExercise(data: any(named: 'data')),
        ).thenAnswer((_) async => '{}'),
      ),
      'CourseExerciseDelete': (
        const CourseExerciseDelete('E1'),
        (r) => when(
          () => r.deleteCourseExercise(exerciseId: 'E1'),
        ).thenAnswer((_) async => '{}'),
      ),
    };

    for (final MapEntry(key: name, value: (event, stub)) in edits.entries) {
      blocTest<CourseBloc, CourseState>(
        '${name.replaceAll(' ', '_')}_selectedCourse_savesAndReloadsDetail',
        setUp: () {
          stub(restClient);
          stubDetail();
        },
        build: build,
        seed: () => CourseState(selectedCourse: flutter),
        act: (bloc) => bloc.add(event),
        verify: (bloc) {
          verify(() => restClient.getCourse(courseId: 'C1')).called(1);
          expect(bloc.state.status, CourseBlocStatus.success);
          expect(bloc.state.selectedCourse?.modules, hasLength(1));
        },
      );
    }

    blocTest<CourseBloc, CourseState>(
      'CourseExerciseSave_nullFields_areNotSent',
      setUp: () => when(
        () => restClient.createCourseExercise(data: any(named: 'data')),
      ).thenAnswer((_) async => '{}'),
      build: build,
      act: (bloc) => bloc.add(CourseExerciseSave(CourseExercise(title: 'x'))),
      verify: (_) {
        final data =
            verify(
                  () => restClient.createCourseExercise(
                    data: captureAny(named: 'data'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(data.values, isNot(contains(null)));
      },
    );

    blocTest<CourseBloc, CourseState>(
      'CourseModuleUpdate_noSelectedCourse_doesNotReload',
      setUp: () => when(
        () => restClient.updateCourseModule(data: any(named: 'data')),
      ).thenAnswer((_) async => '{}'),
      build: build,
      act: (bloc) => bloc.add(CourseModuleUpdate(module)),
      expect: () => [courseState(CourseBlocStatus.loading)],
      verify: (_) => verifyNever(
        () => restClient.getCourse(courseId: any(named: 'courseId')),
      ),
    );

    blocTest<CourseBloc, CourseState>(
      'CourseLessonDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCourseLesson(lessonId: 'L1'),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      seed: () => CourseState(selectedCourse: flutter),
      act: (bloc) => bloc.add(CourseLessonDelete(lesson)),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(CourseBlocStatus.failure),
      ],
    );
  });

  group('CourseParticipantsFetch / CourseMediaGenerate', () {
    blocTest<CourseBloc, CourseState>(
      'CourseParticipantsFetch_course_setsParticipants',
      setUp: () => when(() => restClient.getCourseParticipants(courseId: 'C1'))
          .thenAnswer(
            (_) async => CourseParticipants(
              participants: [CourseParticipant(firstName: 'Jane')],
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(const CourseParticipantsFetch('C1')),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(
          CourseBlocStatus.success,
        ).having((s) => s.participants.single.firstName, 'participant', 'Jane'),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'CourseMediaGenerate_lesson_sendsUpperCaseEnumsAndOptionalIds',
      setUp: () => when(
        () => restClient.generateCourseMedia(
          data: {
            'courseId': 'C1',
            'platform': 'LINKEDIN',
            'mediaType': 'POST',
            'lessonId': 'L1',
          },
        ),
      ).thenAnswer((_) async => '{}'),
      build: build,
      act: (bloc) => bloc.add(
        const CourseMediaGenerate(
          courseId: 'C1',
          platform: MediaPlatform.linkedin,
          mediaType: MediaType.post,
          lessonId: 'L1',
        ),
      ),
      expect: () => [
        courseState(CourseBlocStatus.loading),
        courseState(
          CourseBlocStatus.success,
          message: 'Media content generated successfully for linkedin',
        ),
      ],
    );
  });
}
