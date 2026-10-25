import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

const appId = 'AppAdmin';

TypeMatcher<MenuConfigState> menuState(
  MenuConfigStatus status, {
  MenuConfiguration? config,
  String? message,
}) {
  var m = isA<MenuConfigState>().having((s) => s.status, 'status', status);
  if (config != null) {
    m = m.having((s) => s.menuConfiguration, 'menuConfiguration', config);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  const orders = MenuItem(menuItemId: 'M1', title: 'Orders', sequenceNum: 10);
  const users = MenuItem(menuItemId: 'M2', title: 'Users', sequenceNum: 20);
  const config = MenuConfiguration(
    menuConfigurationId: 'MC1',
    appId: appId,
    name: 'admin',
    menuItems: [orders, users],
  );
  const reloaded = MenuConfiguration(
    menuConfigurationId: 'MC2',
    appId: appId,
    name: 'admin (user)',
  );

  setUp(() => restClient = MockRestClient());

  MenuConfigBloc build() => MenuConfigBloc(restClient, appId);

  void stubReload() => when(
    () => restClient.getMenuConfiguration(appId: appId, userVersion: true),
  ).thenAnswer((_) async => reloaded);

  group('MenuConfigLoad', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigLoad_otherApp_loadsThatAppsMenu',
      setUp: () => when(
        () => restClient.getMenuConfiguration(appId: 'AppHotel'),
      ).thenAnswer((_) async => config),
      build: build,
      act: (bloc) => bloc.add(const MenuConfigLoad(appId: 'AppHotel')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.success, config: config),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigLoad_userVersion_requestsUserVersion',
      setUp: stubReload,
      build: build,
      act: (bloc) => bloc.add(const MenuConfigLoad(userVersion: true)),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.success, config: reloaded),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getMenuConfiguration(appId: appId),
      ).thenThrow(dioError('No menu')),
      build: build,
      act: (bloc) => bloc.add(const MenuConfigLoad()),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.failure, message: 'No menu'),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigLoad_parseError_emitsFailureInsteadOfSpinning',
      setUp: () => when(
        () => restClient.getMenuConfiguration(appId: appId),
      ).thenThrow(const FormatException('bad json')),
      build: build,
      act: (bloc) => bloc.add(const MenuConfigLoad()),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.failure),
      ],
    );
  });

  blocTest<MenuConfigBloc, MenuConfigState>(
    'MenuConfigUpdateLocal_config_replacesWithoutBackend',
    build: build,
    act: (bloc) => bloc.add(const MenuConfigUpdateLocal(config)),
    expect: () => [menuState(MenuConfigStatus.success, config: config)],
    verify: (_) => verifyZeroInteractions(restClient),
  );

  group('MenuItemCreate', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemCreate_withGroups_sendsGroupsAsJsonAndReloadsUserMenu',
      setUp: () {
        when(
          () => restClient.createMenuItem(
            menuConfigurationId: 'MC1',
            title: 'Reports',
            route: '/reports',
            userGroupsJson: '["GROWERP_M_ADMIN"]',
            sequenceNum: 10,
            isActive: 'Y',
          ),
        ).thenAnswer((_) async => const MenuItem(title: 'Reports'));
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(
        const MenuItemCreate(
          menuConfigurationId: 'MC1',
          menuOption: MenuItem(
            title: 'Reports',
            route: '/reports',
            userGroups: [UserGroup.admin],
          ),
        ),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          config: reloaded,
          message: 'Menu option created successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createMenuItem(
          menuConfigurationId: 'MC1',
          title: 'Reports',
          sequenceNum: 10,
          isActive: 'Y',
        ),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      act: (bloc) => bloc.add(
        const MenuItemCreate(
          menuConfigurationId: 'MC1',
          menuOption: MenuItem(title: 'Reports'),
        ),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('MenuItemUpdate / Delete / ToggleActive / Visibility', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemUpdate_inactive_sendsNAndReloads',
      setUp: () {
        when(
          () => restClient.updateMenuItem(
            menuItemId: 'M1',
            title: 'Orders',
            sequenceNum: 10,
            isActive: 'N',
          ),
        ).thenAnswer((_) async => orders);
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(
        MenuItemUpdate(
          menuItemId: 'M1',
          menuOption: orders.copyWith(isActive: false),
        ),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          config: reloaded,
          message: 'Menu option updated successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemDelete_item_deletesAndReloads',
      setUp: () {
        when(
          () => restClient.deleteMenuItem(menuItemId: 'M1'),
        ).thenAnswer((_) async => {'deleted': 1});
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(const MenuItemDelete('M1')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Menu option deleted successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemToggleActive_item_togglesAndReloads',
      setUp: () {
        when(
          () => restClient.toggleMenuItemActive(menuItemId: 'M1'),
        ).thenAnswer((_) async {});
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(const MenuItemToggleActive('M1')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Menu option visibility toggled',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuWidgetVisibilitySet_hide_setsAndReloads',
      setUp: () {
        when(
          () => restClient.setUserMenuWidgetVisibility(
            widgetName: 'UserList',
            hidden: true,
          ),
        ).thenAnswer((_) async {});
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(
        const MenuWidgetVisibilitySet(widgetName: 'UserList', hidden: true),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Menu option visibility changed',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteMenuItem(menuItemId: 'M1'),
      ).thenThrow(dioError('Seed item')),
      build: build,
      act: (bloc) => bloc.add(const MenuItemDelete('M1')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.failure, message: 'Seed item'),
      ],
    );
  });

  group('MenuItemsReorder', () {
    final sequences = [
      {'menuItemId': 'M1', 'sequenceNum': 30},
      {'menuItemId': 'M2', 'sequenceNum': 5},
    ];

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemsReorder_newSequence_reordersLocallyThenReloads',
      setUp: () {
        when(
          () => restClient.reorderMenuItems(
            menuConfigurationId: 'MC1',
            itemSequences: sequences,
          ),
        ).thenAnswer((_) async => {'updated': 2});
        stubReload();
      },
      build: build,
      seed: () => const MenuConfigState(menuConfiguration: config),
      act: (bloc) => bloc.add(
        MenuItemsReorder(
          menuConfigurationId: 'MC1',
          optionSequences: sequences,
        ),
      ),
      expect: () => [
        menuState(MenuConfigStatus.success).having(
          (s) => s.menuConfiguration!.menuItems.map(
            (m) => '${m.menuItemId}:${m.sequenceNum}',
          ),
          'items',
          ['M2:5', 'M1:30'],
        ),
        menuState(
          MenuConfigStatus.success,
          config: reloaded,
          message: 'Menu options reordered successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemsReorder_restThrowsDio_keepsLocalOrderAndReportsFailure',
      setUp: () => when(
        () => restClient.reorderMenuItems(
          menuConfigurationId: 'MC1',
          itemSequences: sequences,
        ),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      seed: () => const MenuConfigState(menuConfiguration: config),
      act: (bloc) => bloc.add(
        MenuItemsReorder(
          menuConfigurationId: 'MC1',
          optionSequences: sequences,
        ),
      ),
      expect: () => [
        menuState(MenuConfigStatus.success),
        menuState(MenuConfigStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('MenuItemToggleMinimize', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemToggleMinimize_expanded_minimizesInPlaceAndPersists',
      setUp: () => when(
        () => restClient.updateMenuItem(menuItemId: 'M1', isMinimized: 'Y'),
      ).thenAnswer((_) async => orders),
      build: build,
      seed: () => const MenuConfigState(menuConfiguration: config),
      act: (bloc) => bloc.add(const MenuItemToggleMinimize('M1')),
      expect: () => [
        menuState(MenuConfigStatus.success).having(
          (s) => s.menuConfiguration!.menuItems.map(
            (m) => '${m.menuItemId}:${m.isMinimized}',
          ),
          'items',
          ['M1:true', 'M2:false'],
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemToggleMinimize_minimized_restoresAndMovesToEnd',
      setUp: () => when(
        () => restClient.updateMenuItem(menuItemId: 'M1', isMinimized: 'N'),
      ).thenAnswer((_) async => orders),
      build: build,
      seed: () => MenuConfigState(
        menuConfiguration: config.copyWith(
          menuItems: [orders.copyWith(isMinimized: true), users],
        ),
      ),
      act: (bloc) => bloc.add(const MenuItemToggleMinimize('M1')),
      expect: () => [
        menuState(MenuConfigStatus.success).having(
          (s) => s.menuConfiguration!.menuItems.map(
            (m) => '${m.menuItemId}:${m.isMinimized}',
          ),
          'items',
          ['M2:false', 'M1:false'],
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemToggleMinimize_persistFails_reportsFailure',
      setUp: () => when(
        () => restClient.updateMenuItem(menuItemId: 'M1', isMinimized: 'Y'),
      ).thenThrow(dioError('Offline')),
      build: build,
      seed: () => const MenuConfigState(menuConfiguration: config),
      act: (bloc) => bloc.add(const MenuItemToggleMinimize('M1')),
      expect: () => [
        menuState(MenuConfigStatus.success),
        menuState(
          MenuConfigStatus.failure,
          message: 'Minimize persist failed: Offline',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemToggleMinimize_noConfig_doesNothing',
      build: build,
      act: (bloc) => bloc.add(const MenuItemToggleMinimize('M1')),
      expect: () => <MenuConfigState>[],
    );
  });

  group('MenuItemLink / Unlink', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemLink_noTitle_createsNewTabUnderParent',
      setUp: () {
        when(
          () => restClient.createMenuItem(
            menuConfigurationId: 'MC1',
            parentMenuItemId: 'M1',
            title: 'New Tab',
            widgetName: 'OrderList',
          ),
        ).thenAnswer((_) async => const MenuItem(title: 'New Tab'));
        stubReload();
      },
      build: build,
      seed: () => const MenuConfigState(menuConfiguration: config),
      act: (bloc) => bloc.add(
        const MenuItemLink(parentMenuItemId: 'M1', widgetName: 'OrderList'),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Child menu item added successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuItemUnlink_child_deletesAndReloads',
      setUp: () {
        when(
          () => restClient.deleteMenuItem(menuItemId: 'T1'),
        ).thenAnswer((_) async => {'deleted': 1});
        stubReload();
      },
      build: build,
      act: (bloc) => bloc.add(const MenuItemUnlink(childMenuItemId: 'T1')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Child menu item removed successfully',
        ),
      ],
    );
  });

  group('MenuConfigClone / Save / Reset', () {
    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigClone_source_setsClonedConfig',
      setUp: () => when(
        () => restClient.cloneMenuConfiguration(
          sourceMenuConfigurationId: 'MC1',
          name: 'mine',
        ),
      ).thenAnswer((_) async => reloaded),
      build: build,
      act: (bloc) => bloc.add(
        const MenuConfigClone(sourceMenuConfigurationId: 'MC1', name: 'mine'),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.success, config: reloaded),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigSave_noId_createsConfiguration',
      setUp: () => when(
        () => restClient.createMenuConfiguration(appId: appId, name: 'new'),
      ).thenAnswer((_) async => reloaded),
      build: build,
      act: (bloc) => bloc.add(
        const MenuConfigSave(MenuConfiguration(appId: appId, name: 'new')),
      ),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          config: reloaded,
          message: 'Menu configuration created successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigSave_withId_updatesConfiguration',
      setUp: () => when(
        () => restClient.updateMenuConfiguration(
          menuConfigurationId: 'MC1',
          name: 'admin',
        ),
      ).thenAnswer((_) async => config),
      build: build,
      act: (bloc) => bloc.add(const MenuConfigSave(config)),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          message: 'Menu configuration updated successfully',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigReset_userConfig_resetsAndLoadsSeedMenu',
      setUp: () {
        when(
          () => restClient.resetMenuConfiguration(menuConfigurationId: 'MC2'),
        ).thenAnswer((_) async {});
        when(
          () => restClient.getMenuConfiguration(appId: appId),
        ).thenAnswer((_) async => config);
      },
      build: build,
      act: (bloc) => bloc.add(const MenuConfigReset('MC2')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(
          MenuConfigStatus.success,
          config: config,
          message: 'Menu configuration reset to default',
        ),
      ],
    );

    blocTest<MenuConfigBloc, MenuConfigState>(
      'MenuConfigReset_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.resetMenuConfiguration(menuConfigurationId: 'MC2'),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      act: (bloc) => bloc.add(const MenuConfigReset('MC2')),
      expect: () => [
        menuState(MenuConfigStatus.loading),
        menuState(MenuConfigStatus.failure, message: 'Not allowed'),
      ],
    );
  });
}
