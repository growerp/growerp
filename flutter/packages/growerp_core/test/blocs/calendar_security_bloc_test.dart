import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('CalendarBloc', () {
    final from = DateTime.utc(2026, 10, 1);
    final thru = DateTime.utc(2026, 11, 1);
    const meeting = CalendarItem(itemId: 'E1', title: 'Meeting');

    blocTest<CalendarBloc, CalendarState>(
      'CalendarFetch_period_sendsEpochMillisAndSetsItems',
      setUp: () =>
          when(
            () => restClient.getCalendarItems(
              fromDate: from.millisecondsSinceEpoch,
              thruDate: thru.millisecondsSinceEpoch,
              includeContent: false,
            ),
          ).thenAnswer(
            (_) async => CalendarItems(
              calendarConnected: true,
              calendarItems: [meeting],
            ),
          ),
      build: () => CalendarBloc(restClient),
      act: (bloc) => bloc.add(CalendarFetch(from: from, thru: thru)),
      expect: () => [
        isA<CalendarState>().having(
          (s) => s.status,
          'status',
          CalendarStatus.loading,
        ),
        isA<CalendarState>()
            .having((s) => s.status, 'status', CalendarStatus.success)
            .having((s) => s.items, 'items', [meeting])
            .having((s) => s.calendarConnected, 'calendarConnected', true),
      ],
    );

    blocTest<CalendarBloc, CalendarState>(
      'CalendarFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCalendarItems(
          fromDate: from.millisecondsSinceEpoch,
          thruDate: thru.millisecondsSinceEpoch,
          includeContent: false,
        ),
      ).thenThrow(dioError('Google sync failed')),
      build: () => CalendarBloc(restClient),
      act: (bloc) => bloc.add(CalendarFetch(from: from, thru: thru)),
      expect: () => [
        isA<CalendarState>().having(
          (s) => s.status,
          'status',
          CalendarStatus.loading,
        ),
        isA<CalendarState>()
            .having((s) => s.status, 'status', CalendarStatus.failure)
            .having((s) => s.message, 'message', 'Google sync failed'),
      ],
    );
  });

  group('SecurityBloc', () {
    const ordersTab = MenuItem(title: 'Open orders', route: '/orders/open');
    const settingsTab = MenuItem(title: 'Settings', route: '/settings');
    const orders = MenuItem(
      title: 'Orders',
      route: '/orders',
      children: [ordersTab, settingsTab],
    );
    const users = MenuItem(title: 'Users', route: '/users');
    const config = MenuConfiguration(
      appId: 'AppAdmin',
      name: 'admin',
      menuItems: [orders, users],
    );

    void stubConfig() => when(
      () => restClient.getMenuConfiguration(
        appId: 'AppAdmin',
        userVersion: true,
        includeAllGroups: true,
      ),
    ).thenAnswer((_) async => config);

    Iterable<String> rows(SecurityState s) =>
        s.menuItems.map((r) => '${r.depth}:${r.item.title}');

    blocTest<SecurityBloc, SecurityState>(
      'SecurityFetch_noSearch_flattensScreensWithTheirTabs',
      setUp: stubConfig,
      build: () => SecurityBloc(restClient, 'AppAdmin'),
      act: (bloc) => bloc.add(const SecurityFetch()),
      expect: () => [
        isA<SecurityState>().having(
          (s) => s.status,
          'status',
          SecurityStatus.loading,
        ),
        isA<SecurityState>().having(rows, 'rows', [
          '0:Orders',
          '1:Open orders',
          '1:Settings',
          '0:Users',
        ]),
      ],
    );

    blocTest<SecurityBloc, SecurityState>(
      'SecurityFetch_searchMatchesTab_keepsParentAndMatchingTabOnly',
      setUp: stubConfig,
      build: () => SecurityBloc(restClient, 'AppAdmin'),
      act: (bloc) => bloc.add(const SecurityFetch(searchString: 'OPEN')),
      expect: () => [
        isA<SecurityState>(),
        isA<SecurityState>()
            .having(rows, 'rows', ['0:Orders', '1:Open orders'])
            .having((s) => s.searchString, 'searchString', 'OPEN'),
      ],
    );

    blocTest<SecurityBloc, SecurityState>(
      'SecurityFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getMenuConfiguration(
          appId: 'AppAdmin',
          userVersion: true,
          includeAllGroups: true,
        ),
      ).thenThrow(dioError('No access')),
      build: () => SecurityBloc(restClient, 'AppAdmin'),
      act: (bloc) => bloc.add(const SecurityFetch()),
      expect: () => [
        isA<SecurityState>(),
        isA<SecurityState>()
            .having((s) => s.status, 'status', SecurityStatus.failure)
            .having((s) => s.message, 'message', 'No access'),
      ],
    );

    blocTest<SecurityBloc, SecurityState>(
      'SecurityUpdate_groups_savesGroupValuesAndRereadsMenu',
      setUp: () {
        when(
          () => restClient.setMenuItemGroups(
            menuItemId: 'M1',
            userGroups: [UserGroup.admin.value],
            updateGroups: [UserGroup.admin.value],
          ),
        ).thenAnswer((_) async {});
        stubConfig();
      },
      build: () => SecurityBloc(restClient, 'AppAdmin'),
      seed: () => const SecurityState(searchString: 'user'),
      act: (bloc) => bloc.add(
        const SecurityUpdate(
          menuItemId: 'M1',
          userGroups: [UserGroup.admin],
          updateGroups: [UserGroup.admin],
        ),
      ),
      expect: () => [
        isA<SecurityState>(),
        isA<SecurityState>()
            .having((s) => s.status, 'status', SecurityStatus.success)
            .having(rows, 'rows', ['0:Users']),
      ],
    );

    blocTest<SecurityBloc, SecurityState>(
      'SecurityUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.setMenuItemGroups(
          menuItemId: 'M1',
          userGroups: [],
          updateGroups: [],
        ),
      ).thenThrow(dioError('Not allowed')),
      build: () => SecurityBloc(restClient, 'AppAdmin'),
      act: (bloc) => bloc.add(
        const SecurityUpdate(
          menuItemId: 'M1',
          userGroups: [],
          updateGroups: [],
        ),
      ),
      expect: () => [
        isA<SecurityState>(),
        isA<SecurityState>()
            .having((s) => s.status, 'status', SecurityStatus.failure)
            .having((s) => s.message, 'message', 'Not allowed'),
      ],
    );
  });
}
