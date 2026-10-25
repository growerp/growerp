import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  final l1 = CourseLesson(lessonId: 'L1', title: 'Widgets');
  final l2 = CourseLesson(lessonId: 'L2', title: 'State');
  final l3 = CourseLesson(lessonId: 'L3', title: 'Bloc');
  final course = Course(
    courseId: 'C1',
    title: 'Flutter',
    modules: [
      CourseModule(moduleId: 'M1', title: 'Basics', lessons: [l1, l2]),
      CourseModule(moduleId: 'M2', title: 'Advanced', lessons: [l3]),
    ],
  );

  String progressJson(List<String> completed) => jsonEncode({
    'progress': CourseProgress(
      courseId: 'C1',
      completedLessons: completed,
    ).toJson(),
  });

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() {
    restClient = MockRestClient();
    when(
      () => restClient.getCourseCatalog(courseId: 'C1'),
    ).thenAnswer((_) async => courseJson(course));
    when(
      () => restClient.listCourseMedia(courseId: 'C1'),
    ).thenAnswer((_) async => CourseMediaList(mediaList: []));
    when(
      () => restClient.getCourseRecommendation(courseId: 'C1'),
    ).thenThrow(dioError('none'));
  });

  CourseViewerBloc build() => CourseViewerBloc(restClient: restClient);

  group('LoadCourse', () {
    blocTest<CourseViewerBloc, CourseViewerState>(
      'LoadCourse_firstLessonDone_opensFirstNotCompletedLesson',
      setUp: () => when(
        () => restClient.getCourseProgress(courseId: 'C1'),
      ).thenAnswer((_) async => progressJson(['L1'])),
      build: build,
      act: (bloc) => bloc.add(const LoadCourse('C1')),
      expect: () => [
        isA<CourseViewerState>().having(
          (s) => s.status,
          'status',
          ViewerStatus.loading,
        ),
        isA<CourseViewerState>()
            .having((s) => s.status, 'status', ViewerStatus.success)
            .having((s) => s.currentLesson?.lessonId, 'lesson', 'L2'),
      ],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'LoadCourse_allLessonsDone_opensFirstLesson',
      setUp: () => when(
        () => restClient.getCourseProgress(courseId: 'C1'),
      ).thenAnswer((_) async => progressJson(['L1', 'L2', 'L3'])),
      build: build,
      act: (bloc) => bloc.add(const LoadCourse('C1')),
      verify: (bloc) => expect(bloc.state.currentLesson?.lessonId, 'L1'),
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'LoadCourse_emptyId_listsSubscribedCourses',
      setUp: () => when(
        () => restClient.getMyCourseSubscriptions(),
      ).thenAnswer((_) async => Courses(courses: [course])),
      build: build,
      act: (bloc) => bloc.add(const LoadCourse('')),
      expect: () => [
        isA<CourseViewerState>().having(
          (s) => s.status,
          'status',
          ViewerStatus.loading,
        ),
        isA<CourseViewerState>()
            .having((s) => s.status, 'status', ViewerStatus.selectingCourse)
            .having((s) => s.availableCourses, 'courses', [course]),
      ],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'LoadCourse_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCourseCatalog(courseId: 'C1'),
      ).thenThrow(dioError('Not subscribed')),
      build: build,
      act: (bloc) => bloc.add(const LoadCourse('C1')),
      expect: () => [
        isA<CourseViewerState>(),
        isA<CourseViewerState>().having(
          (s) => s.status,
          'status',
          ViewerStatus.failure,
        ),
      ],
    );
  });

  group('lesson navigation', () {
    CourseViewerState at(CourseLesson lesson) =>
        CourseViewerState(course: course, currentLesson: lesson);

    blocTest<CourseViewerBloc, CourseViewerState>(
      'NextLesson_lastOfModule_movesToNextModule',
      build: build,
      seed: () => at(l2),
      act: (bloc) => bloc.add(const NextLesson()),
      expect: () => [
        isA<CourseViewerState>().having(
          (s) => s.currentLesson?.lessonId,
          'lesson',
          'L3',
        ),
      ],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'NextLesson_lastLesson_staysPut',
      build: build,
      seed: () => at(l3),
      act: (bloc) => bloc.add(const NextLesson()),
      expect: () => <CourseViewerState>[],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'PreviousLesson_firstLesson_staysPut',
      build: build,
      seed: () => at(l1),
      act: (bloc) => bloc.add(const PreviousLesson()),
      expect: () => <CourseViewerState>[],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'SelectLesson_lesson_setsCurrentLesson',
      build: build,
      seed: () => at(l1),
      act: (bloc) => bloc.add(SelectLesson(l3)),
      expect: () => [
        isA<CourseViewerState>().having(
          (s) => s.currentLesson?.lessonId,
          'lesson',
          'L3',
        ),
      ],
    );
  });

  group('progress', () {
    blocTest<CourseViewerBloc, CourseViewerState>(
      'MarkLessonComplete_stringPercent_parsesAndAddsLesson',
      setUp: () => when(
        () => restClient.updateCourseProgress(
          data: {'courseId': 'C1', 'lessonId': 'L1', 'completed': true},
        ),
      ).thenAnswer((_) async => jsonEncode({'progressPercent': '33'})),
      build: build,
      seed: () => CourseViewerState(course: course),
      act: (bloc) => bloc.add(const MarkLessonComplete('L1')),
      verify: (bloc) {
        expect(bloc.state.progress?.progressPercent, 33);
        expect(bloc.state.progress?.completedLessons, ['L1']);
      },
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'MarkLessonComplete_noCourse_doesNothing',
      build: build,
      act: (bloc) => bloc.add(const MarkLessonComplete('L1')),
      expect: () => <CourseViewerState>[],
    );

    blocTest<CourseViewerBloc, CourseViewerState>(
      'QuizScored_lowerThanBest_keepsBestScore',
      build: build,
      seed: () =>
          CourseViewerState(progress: CourseProgress(quizScores: {'M1': 80})),
      act: (bloc) => bloc
        ..add(const QuizScored('M1', 60))
        ..add(const QuizScored('M2', 90)),
      verify: (bloc) =>
          expect(bloc.state.progress?.quizScores, {'M1': 80, 'M2': 90}),
    );
  });

  blocTest<CourseViewerBloc, CourseViewerState>(
    'SelectMedia_media_setsSelectedMedia',
    build: build,
    act: (bloc) => bloc.add(SelectMedia(CourseMedia(mediaId: 'MD1'))),
    expect: () => [
      isA<CourseViewerState>().having(
        (s) => s.selectedMedia?.mediaId,
        'media',
        'MD1',
      ),
    ],
  );
}
