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

import 'package:flutter_bloc/flutter_bloc.dart' show Bloc;
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:core_example/main.dart';
import 'dart:math';

/// Test data for menu options
final testMenuOptions = [
  const MenuOption(
    title: 'Test Option 1',
    route: '/test1',
    iconName: 'home',
    widgetName: 'CoreDashboard',
    sequenceNum: 100,
    isActive: true,
  ),
  const MenuOption(
    title: 'Test Option 2',
    route: '/test2',
    iconName: 'people',
    widgetName: 'UserList',
    sequenceNum: 110,
    isActive: true,
  ),
];

final updatedMenuOptions = [
  const MenuOption(
    title: 'Updated Option 1',
    route: '/updated1',
    iconName: 'business',
    widgetName: 'ShowCompanyDialog',
    sequenceNum: 100,
    isActive: true,
  ),
  const MenuOption(
    title: 'Updated Option 2',
    route: '/updated2',
    iconName: 'info',
    widgetName: 'AboutForm',
    sequenceNum: 110,
    isActive: true,
  ),
];

/// Test data for menu items (tabs) to add to menu options
final testMenuItems = [
  const MenuItem(
    menuItemId: 'USERLIST',
    title: 'Users Tab',
    widgetName: 'UserList',
    iconName: 'people',
  ),
  const MenuItem(
    menuItemId: 'COMPANYUSERLIST',
    title: 'Companies Tab',
    widgetName: 'CompanyUserList',
    iconName: 'business',
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await PersistFunctions.removeAuthenticate();
    await PersistFunctions.persistTest(SaveTest());
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP dynamic menu CRUD test', (tester) async {
    final restClient = RestClient(await buildDioClient());

    bool clear = true;
    int seq = Random.secure().nextInt(1024);
    if (clear == true) {
      await PersistFunctions.persistTest(SaveTest(sequence: seq));
      // Also clear any stored authentication
      await PersistFunctions.removeAuthenticate();
    } else {
      SaveTest test = await PersistFunctions.getTest();
      await PersistFunctions.persistTest(test.copyWith(sequence: seq));
    }
    Bloc.observer = AppBlocObserver();

    await tester.pumpWidget(
      CoreApp(
        restClient: restClient,
        classificationId: 'AppAdmin',
        chatClient: WsClient('chat'),
        notificationClient: WsClient('notws'),
      ),
    );

    await tester.pump();

    // Wait for menu to load
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoadingIndicator).evaluate().isEmpty) break;
    }

    // Login
    await CommonTest.createCompanyAndAdmin(tester);

    // Add menu options
    await DynamicMenuTest.addMenuOptions(tester, testMenuOptions);
    await DynamicMenuTest.checkMenuOptions(tester);

    // Update menu options
    await DynamicMenuTest.updateMenuOptions(tester, updatedMenuOptions);
    await DynamicMenuTest.checkMenuOptions(tester);

    // Add menu items (tabs) to the first menu option
    await DynamicMenuTest.addMenuItems(tester, testMenuItems);
    await DynamicMenuTest.checkMenuItems(tester, testMenuItems);

    // Delete a menu item (tab) from the menu option
    await DynamicMenuTest.deleteMenuItems(tester);

    // Verify persistence after logout/login
    await DynamicMenuTest.verifyMenuPersistence(tester);

    // Delete menu options
    await DynamicMenuTest.deleteLastMenuOption(tester);

    // Reset to default
    await DynamicMenuTest.resetMenuToDefault(tester);
    await DynamicMenuTest.closeMenuOptions(tester);
    await CommonTest.logout(tester);
  });
}
