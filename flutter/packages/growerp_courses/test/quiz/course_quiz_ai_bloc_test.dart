import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_courses/src/course_ai/bloc/course_ai_bloc.dart';
import 'package:growerp_courses/src/quiz/bloc/course_quiz_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() => restClient = MockRestClient());

  group('CourseQuizBloc', () {
    final quiz = CourseQuiz(
      questions: [
        CourseQuizQuestion(question: 'One?', options: ['a', 'b']),
        CourseQuizQuestion(question: 'Two?', options: ['a', 'b']),
      ],
    );

    CourseQuizBloc build({bool placement = false}) => CourseQuizBloc(
      restClient: restClient,
      courseId: 'C1',
      moduleId: 'M1',
      placement: placement,
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizLoad_quiz_startsAnsweringWithEmptyAnswers',
      setUp: () => when(
        () => restClient.getCourseQuiz(courseId: 'C1', moduleId: 'M1'),
      ).thenAnswer((_) async => quiz),
      build: build,
      act: (bloc) => bloc.add(const CourseQuizLoad()),
      expect: () => [
        isA<CourseQuizState>()
            .having((s) => s.status, 'status', CourseQuizStatus.answering)
            .having((s) => s.answers, 'answers', [null, null]),
      ],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCourseQuiz(courseId: 'C1', moduleId: 'M1'),
      ).thenThrow(dioError('Not subscribed')),
      build: build,
      act: (bloc) => bloc.add(const CourseQuizLoad()),
      expect: () => [
        isA<CourseQuizState>()
            .having((s) => s.status, 'status', CourseQuizStatus.failure)
            .having((s) => s.message, 'message', 'Not subscribed'),
      ],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizAnswer_whileAnswering_recordsOption',
      build: build,
      seed: () => CourseQuizState(
        status: CourseQuizStatus.answering,
        questions: quiz.questions,
        answers: const [null, null],
      ),
      act: (bloc) => bloc.add(const CourseQuizAnswer(1, 0)),
      expect: () => [
        isA<CourseQuizState>().having((s) => s.answers, 'answers', [null, 0]),
      ],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizAnswer_afterSubmit_isIgnored',
      build: build,
      seed: () => const CourseQuizState(
        status: CourseQuizStatus.submitted,
        answers: [1, 0],
      ),
      act: (bloc) => bloc.add(const CourseQuizAnswer(0, 0)),
      expect: () => <CourseQuizState>[],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizSubmit_placementTest_sendsAnswersAndPlacementFlag',
      setUp: () =>
          when(
            () => restClient.submitCourseQuiz(
              courseId: 'C1',
              moduleId: 'M1',
              answers: [1, 0],
              placement: true,
            ),
          ).thenAnswer(
            (_) async => CourseQuizResult(scorePercent: 100, passed: true),
          ),
      build: () => build(placement: true),
      seed: () => const CourseQuizState(
        status: CourseQuizStatus.answering,
        answers: [1, 0],
      ),
      act: (bloc) => bloc.add(const CourseQuizSubmit()),
      expect: () => [
        isA<CourseQuizState>().having(
          (s) => s.status,
          'status',
          CourseQuizStatus.submitting,
        ),
        isA<CourseQuizState>()
            .having((s) => s.status, 'status', CourseQuizStatus.submitted)
            .having((s) => s.result?.passed, 'passed', true),
      ],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizSubmit_restThrowsDio_returnsToAnsweringWithMessage',
      setUp: () => when(
        () => restClient.submitCourseQuiz(
          courseId: 'C1',
          moduleId: 'M1',
          answers: [1, null],
          placement: false,
        ),
      ).thenThrow(dioError('Answer all questions')),
      build: build,
      seed: () => const CourseQuizState(
        status: CourseQuizStatus.answering,
        answers: [1, null],
      ),
      act: (bloc) => bloc.add(const CourseQuizSubmit()),
      expect: () => [
        isA<CourseQuizState>(),
        isA<CourseQuizState>()
            .having((s) => s.status, 'status', CourseQuizStatus.answering)
            .having((s) => s.message, 'message', 'Answer all questions'),
      ],
    );

    blocTest<CourseQuizBloc, CourseQuizState>(
      'CourseQuizRetry_submitted_clearsAnswers',
      build: build,
      seed: () => CourseQuizState(
        status: CourseQuizStatus.submitted,
        questions: quiz.questions,
        answers: const [1, 0],
      ),
      act: (bloc) => bloc.add(const CourseQuizRetry()),
      expect: () => [
        isA<CourseQuizState>()
            .having((s) => s.status, 'status', CourseQuizStatus.answering)
            .having((s) => s.answers, 'answers', [null, null]),
      ],
    );
  });

  group('CourseAiBloc', () {
    const poll = Duration(milliseconds: 10);

    CourseAiBloc build() =>
        CourseAiBloc(restClient: restClient, pollInterval: poll);

    String jobJson(String status) => jsonEncode({
      'courseAiJob': CourseAiJob(jobId: 'J1', status: status).toJson(),
    });

    blocTest<CourseAiBloc, CourseAiState>(
      'CourseAiStart_jobFinishes_pollsUntilDone',
      setUp: () {
        when(
          () => restClient.createCourseAiJob(data: {'jobType': 'OUTLINE'}),
        ).thenAnswer((_) async => jobJson('QUEUED'));
        var calls = 0;
        when(() => restClient.getCourseAiJobs(jobId: 'J1')).thenAnswer(
          (_) async => CourseAiJobs(
            courseAiJobs: [
              CourseAiJob(
                jobId: 'J1',
                status: ++calls < 2 ? 'RUNNING' : 'DONE',
                statusMessage: 'Outline ready',
              ),
            ],
          ),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const CourseAiStart({'jobType': 'OUTLINE'})),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<CourseAiState>().having(
          (s) => s.status,
          's',
          CourseAiStatus.running,
        ),
        isA<CourseAiState>().having((s) => s.job?.jobId, 'job', 'J1'),
        isA<CourseAiState>().having((s) => s.job?.status, 'job', 'RUNNING'),
        isA<CourseAiState>()
            .having((s) => s.status, 's', CourseAiStatus.success)
            .having((s) => s.message, 'message', 'Outline ready'),
      ],
    );

    blocTest<CourseAiBloc, CourseAiState>(
      'CourseAiStart_jobErrors_emitsFailureWithJobError',
      setUp: () {
        when(
          () => restClient.createCourseAiJob(data: any(named: 'data')),
        ).thenAnswer((_) async => jobJson('QUEUED'));
        when(() => restClient.getCourseAiJobs(jobId: 'J1')).thenAnswer(
          (_) async => CourseAiJobs(
            courseAiJobs: [
              CourseAiJob(jobId: 'J1', status: 'ERROR', errorMessage: 'No key'),
            ],
          ),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const CourseAiStart({'jobType': 'LESSONS'})),
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.status, CourseAiStatus.failure);
        expect(bloc.state.message, 'No key');
      },
    );

    blocTest<CourseAiBloc, CourseAiState>(
      'CourseAiStart_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createCourseAiJob(data: any(named: 'data')),
      ).thenThrow(dioError('AI allowance used up')),
      build: build,
      act: (bloc) => bloc.add(const CourseAiStart({'jobType': 'OUTLINE'})),
      expect: () => [
        isA<CourseAiState>().having(
          (s) => s.status,
          's',
          CourseAiStatus.running,
        ),
        isA<CourseAiState>()
            .having((s) => s.status, 's', CourseAiStatus.failure)
            .having((s) => s.message, 'message', 'AI allowance used up'),
      ],
    );

    blocTest<CourseAiBloc, CourseAiState>(
      'CourseAiWatch_runningJob_picksItUp',
      setUp: () {
        when(() => restClient.getCourseAiJobs(courseId: 'C1')).thenAnswer(
          (_) async => CourseAiJobs(
            courseAiJobs: [
              CourseAiJob(jobId: 'J0', status: 'DONE'),
              CourseAiJob(jobId: 'J1', status: 'RUNNING'),
            ],
          ),
        );
        when(() => restClient.getCourseAiJobs(jobId: 'J1')).thenAnswer(
          (_) async => CourseAiJobs(
            courseAiJobs: [CourseAiJob(jobId: 'J1', status: 'RUNNING')],
          ),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const CourseAiWatch('C1')),
      expect: () => [
        isA<CourseAiState>()
            .having((s) => s.status, 's', CourseAiStatus.running)
            .having((s) => s.job?.jobId, 'job', 'J1'),
      ],
    );

    blocTest<CourseAiBloc, CourseAiState>(
      'CourseAiWatch_nothingRunning_staysIdle',
      setUp: () =>
          when(() => restClient.getCourseAiJobs(courseId: 'C1')).thenAnswer(
            (_) async => CourseAiJobs(
              courseAiJobs: [CourseAiJob(jobId: 'J0', status: 'DONE')],
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(const CourseAiWatch('C1')),
      expect: () => <CourseAiState>[],
    );
  });
}
