import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CommunicationState> communicationState(
  CommunicationStatus status, {
  List<CommunicationEvent>? events,
  CommunicationAction? action,
  String? message,
}) {
  var m = isA<CommunicationState>().having((s) => s.status, 'status', status);
  if (events != null) {
    m = m.having((s) => s.communicationEvents, 'communicationEvents', events);
  }
  if (action != null) m = m.having((s) => s.action, 'action', action);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  CommunicationBloc build() =>
      CommunicationBloc(restClient, userPseudoId: 'user1');

  group('CommunicationFetch', () {
    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationFetch_emptySearch_sendsNullSearchAndEmitsFirstPage',
      setUp: () => when(
        () => restClient.getCommunicationEvents(
          userPseudoId: 'user1',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => CommunicationEvents(communicationEvents: [event1, event2]),
      ),
      build: build,
      act: (bloc) => bloc.add(const CommunicationFetch()),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.success,
          events: [event1, event2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getCommunicationEvents(
          userPseudoId: 'user1',
          searchString: 'Re',
          start: 1,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => CommunicationEvents(communicationEvents: [event2]),
      ),
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1],
      ),
      act: (bloc) => bloc.add(const CommunicationFetch(searchString: 'Re')),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.success,
          events: [event1, event2],
        ),
      ],
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationFetch_reachedMaxWithoutRefresh_doesNotFetch',
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1],
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(const CommunicationFetch()),
      expect: () => <CommunicationState>[],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCommunicationEvents(
          userPseudoId: 'user1',
          start: 0,
          limit: 20,
        ),
      ).thenThrow(dioError('Communication service down')),
      build: build,
      act: (bloc) => bloc.add(const CommunicationFetch()),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.failure,
          message: 'Communication service down',
        ),
      ],
    );
  });

  group('CommunicationUpdate', () {
    final newEvent = CommunicationEvent(subject: 'New');
    final created = newEvent.copyWith(communicationEventId: 'E3');
    final changed = event2.copyWith(subject: 'Re: Re');

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationUpdate_noId_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createCommunicationEvent(communicationEvent: newEvent),
      ).thenAnswer((_) async => created),
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1],
      ),
      act: (bloc) => bloc.add(CommunicationUpdate(newEvent)),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.success,
          events: [created, event1],
          action: CommunicationAction.added,
        ),
      ],
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationUpdate_withId_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateCommunicationEvent(communicationEvent: changed),
      ).thenAnswer((_) async => changed),
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1, event2],
      ),
      act: (bloc) => bloc.add(CommunicationUpdate(changed)),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.success,
          events: [event1, changed],
          action: CommunicationAction.updated,
        ),
      ],
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateCommunicationEvent(communicationEvent: changed),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      act: (bloc) => bloc.add(CommunicationUpdate(changed)),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(CommunicationStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('CommunicationDelete', () {
    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationDelete_existing_sendsIdOnlyAndRemovesIt',
      setUp: () => when(
        () => restClient.deleteCommunicationEvent(
          communicationEvent: CommunicationEvent(communicationEventId: 'E1'),
        ),
      ).thenAnswer((_) async => event1),
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1, event2],
      ),
      act: (bloc) => bloc.add(CommunicationDelete(event1)),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(
          CommunicationStatus.success,
          events: [event2],
          action: CommunicationAction.deleted,
        ),
      ],
    );

    blocTest<CommunicationBloc, CommunicationState>(
      'CommunicationDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCommunicationEvent(
          communicationEvent: CommunicationEvent(communicationEventId: 'E1'),
        ),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      seed: () => CommunicationState(
        status: CommunicationStatus.success,
        communicationEvents: [event1],
      ),
      act: (bloc) => bloc.add(CommunicationDelete(event1)),
      expect: () => [
        communicationState(CommunicationStatus.loading),
        communicationState(CommunicationStatus.failure, message: 'Not allowed'),
      ],
    );
  });
}
