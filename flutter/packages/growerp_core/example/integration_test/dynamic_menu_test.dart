/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Test data for top-level menu items
final testMenuItems = [
  const MenuItem(
    title: 'Test Option 1',
    route: '/test1',
    iconName: 'home',
    widgetName: 'CoreDashboard',
    sequenceNum: 100,
    isActive: true,
  ),
  const MenuItem(
    title: 'Test Option 2',
    route: '/test2',
    iconName: 'people',
    widgetName: 'UserList',
    sequenceNum: 110,
    isActive: true,
  ),
];

final updatedMenuItems = [
  const MenuItem(
    title: 'Updated Option 1',
    route: '/updated1',
    iconName: 'business',
    widgetName: 'ShowCompanyDialog',
    sequenceNum: 100,
    isActive: true,
  ),
  const MenuItem(
    title: 'Updated Option 2',
    route: '/updated2',
    iconName: 'info',
    widgetName: 'AboutForm',
    sequenceNum: 110,
    isActive: true,
  ),
];

/// Test data for child menu items (tabs) to add to menu items
final testChildMenuItems = [
  const MenuItem(
    menuItemId: 'USERLIST',
    title: 'Users Tab',
    widgetName: 'UserList',
    iconName: 'people',
  ),
  const MenuItem(
    menuItemId: 'COMPANYUSERLIST',
    title: 'Company User List',
    widgetName: 'CompanyUserList',
    iconName: 'business',
  ),
];

const coreMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CORE_EXAMPLE',
  appId: 'core_example',
  name: 'Core Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'CORE_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'CORE_COMPANY',
      title: 'Organization',
      route: '/company',
      iconName: 'business',
      sequenceNum: 20,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'CORE_USER',
      title: 'Logged in User',
      route: '/user',
      iconName: 'person',
      sequenceNum: 30,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP dynamic menu CRUD test', (tester) async {
    final restClient = RestClient(await buildDioClient());
    final menuConfigBloc = MenuConfigBloc(restClient, 'core_example')
      ..add(MenuConfigUpdateLocal(coreMenuConfig));
    final router = createDynamicCoreRouter(
      [coreMenuConfig],
      rootNavigatorKey: GlobalKey<NavigatorState>(),
      menuConfigBloc: menuConfigBloc,
    );

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: 'Dynamic Menu Test',
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
      ],
    );

    // Login — exercises the GrowERP tenant detection if backend is fresh
    await CommonTest.createCompanyAndAdmin(tester);

    // Load the backend menu config so the FAB uses the correct
    // menuConfigurationId (e.g. CORE_EXAMPLE_DEFAULT) rather than the
    // local static ID (CORE_EXAMPLE) that was pre-loaded before auth.
    menuConfigBloc.add(const MenuConfigLoad(userVersion: true));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Add menu items
    await DynamicMenuTest.addMenuItems(tester, testMenuItems);
    await DynamicMenuTest.checkMenuItems(tester);

    // Verify Company A's custom menu items are not visible to a new company's user.
    await DynamicMenuTest.verifyMenuIsolation(
      tester,
      testMenuItems.map((m) => m.title).toList(),
    );

    // Update menu items
    await DynamicMenuTest.updateMenuItems(tester, updatedMenuItems);
    await DynamicMenuTest.checkMenuItems(tester);

    // Minimize the first dashboard tile, then restore it.
    await DynamicMenuTest.minimizeTile(tester);
    await DynamicMenuTest.restoreTile(tester);

    // Drag-reorder the first two tiles and verify the swap persists.
    await DynamicMenuTest.reorderTiles(tester);
    await DynamicMenuTest.verifyReorderPersistence(tester);

    // Add child menu items (tabs) to the first menu item
    await DynamicMenuTest.addChildMenuItems(tester, testChildMenuItems);
    await DynamicMenuTest.checkChildMenuItems(tester, testChildMenuItems);

    // Delete a child menu item (tab) from the menu item
    await DynamicMenuTest.deleteChildMenuItems(tester);

    // Verify persistence after logout/login
    await DynamicMenuTest.verifyMenuPersistence(tester);

    // Delete menu items
    await DynamicMenuTest.deleteMenuItem(tester);

    // Reset to default
    await DynamicMenuTest.resetMenuToDefault(tester);
    await DynamicMenuTest.closeMenuItems(tester);
    await CommonTest.logout(tester);
  });
}
