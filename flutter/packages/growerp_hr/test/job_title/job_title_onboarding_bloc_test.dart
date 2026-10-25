import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_hr/growerp_hr.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('JobTitleBloc', () {
    final manager = JobTitle(jobTitleId: 'J1', title: 'Manager');
    final clerk = JobTitle(jobTitleId: 'J2', title: 'Clerk');

    TypeMatcher<JobTitleState> jobState(
      JobTitleStatus status, {
      List<JobTitle>? titles,
      String? message,
    }) {
      var m = isA<JobTitleState>().having((s) => s.status, 'status', status);
      if (titles != null) m = m.having((s) => s.jobTitles, 'jobTitles', titles);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    JobTitleBloc build() => JobTitleBloc(restClient);

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitlesFetch_refresh_loadsFirstPage',
      setUp: () => when(
        () => restClient.getJobTitles(start: 0, limit: 20),
      ).thenAnswer((_) async => JobTitles(jobTitles: [manager, clerk])),
      build: build,
      act: (bloc) => bloc.add(const JobTitlesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.success, titles: [manager, clerk]),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitleSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getJobTitles(search: 'Man', start: 0, limit: 20),
      ).thenAnswer((_) async => JobTitles(jobTitles: [manager])),
      build: build,
      act: (bloc) => bloc.add(const JobTitleSearchChanged(searchString: 'Man')),
      wait: searchWait,
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.success, titles: [manager]),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitlesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getJobTitles(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const JobTitlesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.failure, message: 'No access'),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitleUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createJobTitle(jobTitle: JobTitle(title: 'Clerk')),
      ).thenAnswer((_) async => clerk),
      build: build,
      seed: () => JobTitleState(jobTitles: [manager]),
      act: (bloc) => bloc.add(JobTitleUpdate(JobTitle(title: 'Clerk'))),
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.success, titles: [clerk, manager]),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitleUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateJobTitle(
          jobTitle: clerk.copyWith(title: 'Senior clerk'),
        ),
      ).thenAnswer((_) async => clerk.copyWith(title: 'Senior clerk')),
      build: build,
      seed: () => JobTitleState(jobTitles: [manager, clerk]),
      act: (bloc) =>
          bloc.add(JobTitleUpdate(clerk.copyWith(title: 'Senior clerk'))),
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(
          JobTitleStatus.success,
          titles: [
            manager,
            clerk.copyWith(title: 'Senior clerk'),
          ],
        ),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitleDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteJobTitle(jobTitle: manager),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => JobTitleState(jobTitles: [manager, clerk]),
      act: (bloc) => bloc.add(JobTitleDelete(manager)),
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.success, titles: [clerk]),
      ],
    );

    blocTest<JobTitleBloc, JobTitleState>(
      'JobTitleDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteJobTitle(jobTitle: manager),
      ).thenThrow(dioError('In use')),
      build: build,
      act: (bloc) => bloc.add(JobTitleDelete(manager)),
      expect: () => [
        jobState(JobTitleStatus.loading),
        jobState(JobTitleStatus.failure, message: 'In use'),
      ],
    );
  });

  group('OnboardingTaskBloc', () {
    final laptop = OnboardingTask(
      onboardingTaskId: 'T1',
      description: 'Laptop',
    );
    final badge = OnboardingTask(onboardingTaskId: 'T2', description: 'Badge');

    TypeMatcher<OnboardingTaskState> taskState(
      OnboardingTaskStatus status, {
      List<OnboardingTask>? tasks,
      String? message,
    }) {
      var m = isA<OnboardingTaskState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (tasks != null) {
        m = m.having((s) => s.onboardingTasks, 'tasks', tasks);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    OnboardingTaskBloc build() => OnboardingTaskBloc(restClient);

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTasksFetch_refresh_loadsFirstPage',
      setUp: () =>
          when(
            () => restClient.getOnboardingTasks(start: 0, limit: 20),
          ).thenAnswer(
            (_) async => OnboardingTasks(onboardingTasks: [laptop, badge]),
          ),
      build: build,
      act: (bloc) => bloc.add(const OnboardingTasksFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(OnboardingTaskStatus.success, tasks: [laptop, badge]),
      ],
    );

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTasksFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getOnboardingTasks(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const OnboardingTasksFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(OnboardingTaskStatus.failure, message: 'No access'),
      ],
    );

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTaskSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getOnboardingTasks(search: 'Lap', start: 0, limit: 20),
      ).thenAnswer((_) async => OnboardingTasks(onboardingTasks: [laptop])),
      build: build,
      act: (bloc) =>
          bloc.add(const OnboardingTaskSearchChanged(searchString: 'Lap')),
      wait: searchWait,
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(OnboardingTaskStatus.success, tasks: [laptop]),
      ],
    );

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTaskUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createOnboardingTask(
          onboardingTask: OnboardingTask(description: 'Badge'),
        ),
      ).thenAnswer((_) async => badge),
      build: build,
      seed: () => OnboardingTaskState(onboardingTasks: [laptop]),
      act: (bloc) =>
          bloc.add(OnboardingTaskUpdate(OnboardingTask(description: 'Badge'))),
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(OnboardingTaskStatus.success, tasks: [badge, laptop]),
      ],
    );

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTaskUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateOnboardingTask(
          onboardingTask: laptop.copyWith(sequenceNum: 2),
        ),
      ).thenAnswer((_) async => laptop.copyWith(sequenceNum: 2)),
      build: build,
      seed: () => OnboardingTaskState(onboardingTasks: [laptop, badge]),
      act: (bloc) =>
          bloc.add(OnboardingTaskUpdate(laptop.copyWith(sequenceNum: 2))),
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(
          OnboardingTaskStatus.success,
          tasks: [laptop.copyWith(sequenceNum: 2), badge],
        ),
      ],
    );

    blocTest<OnboardingTaskBloc, OnboardingTaskState>(
      'OnboardingTaskDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteOnboardingTask(onboardingTask: laptop),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => OnboardingTaskState(onboardingTasks: [laptop, badge]),
      act: (bloc) => bloc.add(OnboardingTaskDelete(laptop)),
      expect: () => [
        taskState(OnboardingTaskStatus.loading),
        taskState(OnboardingTaskStatus.success, tasks: [badge]),
      ],
    );
  });
}
