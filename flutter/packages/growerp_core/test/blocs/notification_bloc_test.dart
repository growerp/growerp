import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// NotificationFetch is throttled 500ms.
const fetchWait = Duration(milliseconds: 600);

void main() {
  late MockRestClient restClient;
  late MockWsClient wsClient;
  late MockAuthBloc authBloc;
  late StreamController<dynamic> wsStream;
  late StreamController<AuthState> authStream;

  final note1 = NotificationWs(topic: 'ALL', title: 'Demo data loaded');
  final note2 = NotificationWs(topic: 'ALL', title: 'Invoice paid');

  setUp(() {
    restClient = MockRestClient();
    wsClient = MockWsClient();
    authBloc = MockAuthBloc();
    wsStream = StreamController<dynamic>.broadcast();
    authStream = StreamController<AuthState>.broadcast();
    when(() => wsClient.stream()).thenAnswer((_) => wsStream.stream);
    when(() => wsClient.subscribe(any())).thenReturn(null);
    when(() => authBloc.stream).thenAnswer((_) => authStream.stream);
    when(() => authBloc.state).thenReturn(const AuthState());
  });
  tearDown(() {
    wsStream.close();
    authStream.close();
  });

  NotificationBloc build() => NotificationBloc(restClient, wsClient, authBloc);

  blocTest<NotificationBloc, NotificationState>(
    'NotificationBloc_created_subscribesToAllTopics',
    build: build,
    verify: (_) => verify(() => wsClient.subscribe('ALL')).called(1),
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationBloc_createdAfterLogin_fetchesOnce',
    setUp: () {
      when(
        () => authBloc.state,
      ).thenReturn(const AuthState(status: AuthStatus.authenticated));
      when(
        () => restClient.getNotifications(limit: 20),
      ).thenAnswer((_) async => Notifications(notifications: [note1]));
    },
    build: build,
    wait: fetchWait,
    expect: () => [
      isA<NotificationState>()
          .having((s) => s.notifications, 'notifications', [note1])
          .having((s) => s.notificationSeq, 'notificationSeq', 1),
    ],
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationBloc_loginTransition_fetchesOnlyOnTheTransition',
    setUp: () => when(
      () => restClient.getNotifications(limit: 20),
    ).thenAnswer((_) async => Notifications()),
    build: build,
    act: (_) async {
      authStream.add(const AuthState(status: AuthStatus.authenticated));
      await Future<void>.delayed(fetchWait);
      // another emission while still logged in
      authStream.add(const AuthState(status: AuthStatus.authenticated));
    },
    wait: fetchWait,
    verify: (_) =>
        verify(() => restClient.getNotifications(limit: 20)).called(1),
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationFetch_empty_keepsSequence',
    setUp: () => when(
      () => restClient.getNotifications(limit: 5),
    ).thenAnswer((_) async => Notifications()),
    build: build,
    seed: () => const NotificationState(notificationSeq: 3),
    act: (bloc) => bloc.add(const NotificationFetch(limit: 5)),
    wait: fetchWait,
    expect: () => [
      isA<NotificationState>()
          .having((s) => s.status, 'status', NotificationStatus.success)
          .having((s) => s.notificationSeq, 'notificationSeq', 3),
    ],
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationFetch_restThrowsDio_emitsFailure',
    setUp: () => when(
      () => restClient.getNotifications(limit: 20),
    ).thenThrow(dioError('No access')),
    build: build,
    act: (bloc) => bloc.add(const NotificationFetch()),
    wait: fetchWait,
    expect: () => [
      isA<NotificationState>()
          .having((s) => s.status, 'status', NotificationStatus.failure)
          .having((s) => s.message, 'message', 'No access'),
    ],
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationReceive_wsMessage_replacesListAndBumpsSequence',
    build: build,
    seed: () => NotificationState(notifications: [note1], notificationSeq: 1),
    act: (_) => wsStream.add(jsonEncode(note2.toJson())),
    expect: () => [
      isA<NotificationState>()
          .having((s) => s.notifications, 'notifications', [note2])
          .having((s) => s.notificationSeq, 'notificationSeq', 2),
    ],
  );

  blocTest<NotificationBloc, NotificationState>(
    'NotificationReceive_unparsableWsMessage_isIgnored',
    build: build,
    act: (_) => wsStream.add('not json'),
    expect: () => <NotificationState>[],
  );
}
