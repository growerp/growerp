import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// ActivityFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<ActivityState> activityState(
  ActivityBlocStatus status, {
  List<Activity>? activities,
  String? message,
}) {
  var m = isA<ActivityState>().having((s) => s.status, 'status', status);
  if (activities != null) {
    m = m.having((s) => s.activities, 'activities', activities);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  const call = Activity(
    activityId: 'A1',
    activityType: ActivityType.todo,
    activityName: 'Call',
  );
  const visit = Activity(
    activityId: 'A2',
    activityType: ActivityType.todo,
    activityName: 'Visit',
  );

  setUp(() => restClient = MockRestClient());

  ActivityBloc build() => ActivityBloc(restClient);

  group('ActivityFetch', () {
    blocTest<ActivityBloc, ActivityState>(
      'ActivityFetch_myTodos_loadsFirstPage',
      setUp: () => when(
        () => restClient.getActivity(
          activityType: ActivityType.todo,
          my: true,
          start: 0,
          searchString: '',
          limit: 20,
          activityId: '',
          isForDropDown: false,
        ),
      ).thenAnswer((_) async => Activities(activities: [call, visit])),
      build: build,
      act: (bloc) =>
          bloc.add(const ActivityFetch(activityType: ActivityType.todo)),
      wait: fetchWait,
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [call, visit]),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityFetch_forCompany_sendsCompanyPseudoId',
      setUp: () => when(
        () => restClient.getActivity(
          activityType: ActivityType.todo,
          my: true,
          start: 0,
          searchString: '',
          limit: 20,
          activityId: '',
          isForDropDown: false,
          companyPseudoId: 'acme',
        ),
      ).thenAnswer((_) async => Activities(activities: [call])),
      build: build,
      act: (bloc) => bloc.add(
        ActivityFetch(
          activityType: ActivityType.todo,
          companyUser: CompanyUser(
            type: PartyType.company,
            pseudoId: 'acme',
            name: 'Acme',
          ),
        ),
      ),
      wait: fetchWait,
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [call]),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getActivity(
          activityType: ActivityType.unknown,
          my: true,
          start: 0,
          searchString: '',
          limit: 20,
          activityId: '',
          isForDropDown: false,
        ),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const ActivityFetch()),
      wait: fetchWait,
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.failure, message: 'No access'),
      ],
    );
  });

  group('ActivityUpdate', () {
    blocTest<ActivityBloc, ActivityState>(
      'ActivityUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createActivity(
          activity: const Activity(
            activityType: ActivityType.todo,
            activityName: 'Visit',
          ),
        ),
      ).thenAnswer((_) async => visit),
      build: build,
      seed: () => const ActivityState(activities: [call]),
      act: (bloc) => bloc.add(
        const ActivityUpdate(
          Activity(activityType: ActivityType.todo, activityName: 'Visit'),
        ),
      ),
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [visit, call]),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityUpdate_existing_movesToTop',
      setUp: () => when(
        () => restClient.updateActivity(activity: visit),
      ).thenAnswer((_) async => visit),
      build: build,
      seed: () => const ActivityState(activities: [call, visit]),
      act: (bloc) => bloc.add(const ActivityUpdate(visit)),
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [visit, call]),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityUpdate_closed_removesFromList',
      setUp: () => when(
        () => restClient.updateActivity(activity: call),
      ).thenAnswer((_) async => call.copyWith(statusId: ActivityStatus.closed)),
      build: build,
      seed: () => const ActivityState(activities: [call, visit]),
      act: (bloc) => bloc.add(const ActivityUpdate(call)),
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [visit]),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateActivity(activity: call),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      act: (bloc) => bloc.add(const ActivityUpdate(call)),
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('time entries', () {
    final entry = TimeEntry(
      timeEntryId: 'TE1',
      activityId: 'A1',
      hours: Decimal.parse('2'),
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityTimeEntryUpdate_new_addsToConstEntryList',
      setUp: () => when(
        () => restClient.createTimeEntry(
          timeEntry: TimeEntry(activityId: 'A1', hours: Decimal.parse('2')),
        ),
      ).thenAnswer((_) async => entry),
      build: build,
      seed: () => const ActivityState(activities: [call]),
      act: (bloc) => bloc.add(
        ActivityTimeEntryUpdate(
          TimeEntry(activityId: 'A1', hours: Decimal.parse('2')),
        ),
      ),
      expect: () => [
        isA<ActivityState>().having(
          (s) => s.activities.single.timeEntries,
          'timeEntries',
          [entry],
        ),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityTimeEntryUpdate_existing_replacesEntry',
      setUp: () => when(
        () => restClient.updateTimeEntry(
          timeEntry: entry.copyWith(hours: Decimal.parse('3')),
        ),
      ).thenAnswer((_) async => entry.copyWith(hours: Decimal.parse('3'))),
      build: build,
      seed: () => ActivityState(
        activities: [
          call.copyWith(timeEntries: [entry]),
        ],
      ),
      act: (bloc) => bloc.add(
        ActivityTimeEntryUpdate(entry.copyWith(hours: Decimal.parse('3'))),
      ),
      expect: () => [
        isA<ActivityState>().having(
          (s) => s.activities.single.timeEntries.single.hours,
          'hours',
          Decimal.parse('3'),
        ),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityTimeEntryDelete_entry_removesIt',
      setUp: () => when(
        () => restClient.deleteTimeEntry(timeEntry: entry),
      ).thenAnswer((_) async => entry),
      build: build,
      seed: () => ActivityState(
        activities: [
          call.copyWith(timeEntries: [entry]),
        ],
      ),
      act: (bloc) => bloc.add(ActivityTimeEntryDelete(entry)),
      expect: () => [
        activityState(ActivityBlocStatus.success).having(
          (s) => s.activities.single.timeEntries,
          'timeEntries',
          isEmpty,
        ),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'ActivityInvoiceFromTimeEntries_customer_createsInvoiceAndRefreshesTodos',
      setUp: () {
        when(
          () => restClient.createInvoiceFromTimeEntries(
            sales: true,
            partyId: 'C1',
            hourlyRate: '50',
          ),
        ).thenAnswer((_) async => FinDoc(pseudoId: 'inv1'));
        when(
          () => restClient.getActivity(
            activityType: ActivityType.todo,
            my: true,
            start: 0,
            searchString: '',
            limit: 20,
            activityId: '',
            isForDropDown: false,
          ),
        ).thenAnswer((_) async => Activities(activities: [call]));
      },
      build: build,
      act: (bloc) => bloc.add(
        const ActivityInvoiceFromTimeEntries(
          sales: true,
          partyId: 'C1',
          hourlyRate: '50',
        ),
      ),
      wait: fetchWait,
      expect: () => [
        activityState(ActivityBlocStatus.loading),
        activityState(
          ActivityBlocStatus.success,
          message: 'Sales invoice inv1 created',
        ),
        activityState(ActivityBlocStatus.loading),
        activityState(ActivityBlocStatus.success, activities: [call]),
      ],
    );
  });
}
