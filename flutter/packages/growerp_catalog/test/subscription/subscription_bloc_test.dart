import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

Matcher subscriptionState(
  SubscriptionStatus status, {
  List<Subscription>? subscriptions,
  String? message,
  bool? hasReachedMax,
}) {
  var m = isA<SubscriptionState>().having((s) => s.status, 'status', status);
  if (subscriptions != null) {
    m = m.having((s) => s.subscriptions, 'subscriptions', subscriptions);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  if (hasReachedMax != null) {
    m = m.having((s) => s.hasReachedMax, 'hasReachedMax', hasReachedMax);
  }
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('SubscriptionFetch', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionFetch_initial_emitsLoadingThenFirstPage',
      setUp: () =>
          when(
            () => restClient.getSubscription(
              searchString: '',
              growerp: false,
              limit: 20,
              start: 0,
            ),
          ).thenAnswer(
            (_) async =>
                Subscriptions(subscriptions: [subscription1, subscription2]),
          ),
      build: () => SubscriptionBloc(restClient),
      act: (bloc) => bloc.add(const SubscriptionFetch()),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [subscription1, subscription2],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionFetch_growerpNextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getSubscription(
          searchString: '',
          growerp: true,
          limit: 20,
          start: 1,
        ),
      ).thenAnswer((_) async => Subscriptions(subscriptions: [subscription2])),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1],
      ),
      act: (bloc) => bloc.add(const SubscriptionFetch(growerp: true)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [subscription1, subscription2],
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getSubscription(
          searchString: '',
          growerp: false,
          limit: 20,
          start: 0,
        ),
      ).thenThrow(dioError('Subscription service down')),
      build: () => SubscriptionBloc(restClient),
      act: (bloc) => bloc.add(const SubscriptionFetch()),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.failure,
          message: 'Subscription service down',
        ),
      ],
    );
  });

  group('SubscriptionSearchChanged', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => when(
        () => restClient.getSubscription(
          searchString: 'sub',
          growerp: false,
          limit: 20,
          start: 0,
        ),
      ).thenAnswer((_) async => Subscriptions(subscriptions: [subscription1])),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1, subscription2],
      ),
      act: (bloc) =>
          bloc.add(const SubscriptionSearchChanged(searchString: 'sub')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [subscription1],
        ),
      ],
    );
  });

  group('SubscriptionUpdate', () {
    final changed = subscription1.copyWith(pseudoId: 'sub1b');
    final newSubscription = Subscription(pseudoId: 'sub3');
    final created = Subscription(subscriptionId: 'S3', pseudoId: 'sub3');

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateSubscription(subscription: changed),
      ).thenAnswer((_) async => changed),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1, subscription2],
      ),
      act: (bloc) => bloc.add(SubscriptionUpdate(changed)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [changed, subscription2],
          message: 'subscriptionUpdateSuccess',
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createSubscription(subscription: newSubscription),
      ).thenAnswer((_) async => created),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1],
      ),
      act: (bloc) => bloc.add(SubscriptionUpdate(newSubscription)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [created, subscription1],
          message: 'subscriptionAddSuccess',
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateSubscription(subscription: changed),
      ).thenThrow(dioError('Subscription expired')),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1],
      ),
      act: (bloc) => bloc.add(SubscriptionUpdate(changed)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.failure,
          message: 'Subscription expired',
        ),
      ],
    );
  });

  group('SubscriptionDelete', () {
    // The backend ends the subscription (sets thruDate) and returns it.
    final ended = subscription1.copyWith(thruDate: DateTime.utc(2026, 10, 25));

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionDelete_existing_replacesWithEndedSubscription',
      setUp: () => when(
        () => restClient.deleteSubscription(subscription: subscription1),
      ).thenAnswer((_) async => ended),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1, subscription2],
      ),
      act: (bloc) => bloc.add(SubscriptionDelete(subscription1)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(
          SubscriptionStatus.success,
          subscriptions: [ended, subscription2],
          message: 'subscriptionDeleteSuccess',
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'SubscriptionDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteSubscription(subscription: subscription1),
      ).thenThrow(dioError('Not allowed')),
      build: () => SubscriptionBloc(restClient),
      seed: () => SubscriptionState(
        status: SubscriptionStatus.success,
        subscriptions: [subscription1],
      ),
      act: (bloc) => bloc.add(SubscriptionDelete(subscription1)),
      expect: () => [
        subscriptionState(SubscriptionStatus.loading),
        subscriptionState(SubscriptionStatus.failure, message: 'Not allowed'),
      ],
    );
  });
}
