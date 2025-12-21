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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Integration test class for dynamic menu system
/// Keys used:
/// - MenuItemListDialog: the list dialog
/// - addMenuItemFab: add button in list
/// - resetMenuItemsFab: reset button in list
/// - MenuItemDialog: the edit/add dialog
/// - menuItemTitle: title TextFormField
/// - menuItemRoute: route TextFormField
/// - menuItemIcon: icon Autocomplete
/// - menuItemWidget: widget Autocomplete
/// - menuItemSequence: sequence TextFormField
/// - menuItemActive: active SwitchListTile
/// - menuItemUpdate: save FloatingActionButton
class DynamicMenuTest {
  /// Navigate to the Menu Item List Dialog via dashboard FAB
  static Future<void> selectMenuOptions(WidgetTester tester) async {
    // Tap on the dashboard FAB to access menu configuration
    if (await CommonTest.doesExistKey(tester, 'coreFab')) {
      await CommonTest.tapByKey(
        tester,
        'coreFab',
        seconds: CommonTest.waitTime,
      );
    } else if (await CommonTest.doesExistKey(tester, 'menuFab')) {
      await CommonTest.tapByKey(
        tester,
        'menuFab',
        seconds: CommonTest.waitTime,
      );
    } else {
      throw Exception('Could not find menu config FAB (coreFab or menuFab)');
    }
  }

  /// Add menu options from the provided list
  /// Calls selectMenuOptions before each add since list closes after saving
  static Future<void> addMenuOptions(
    WidgetTester tester,
    List<MenuOption> menuOptions,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    List<MenuOption> createdOptions = [];

    for (final option in menuOptions) {
      // Navigate to menu config list (closes after each save)
      await selectMenuOptions(tester);

      // Tap add button
      await CommonTest.tapByKey(
        tester,
        'addMenuItemFab',
        seconds: CommonTest.waitTime,
      );

      // Enter menu option data
      await _enterMenuOptionData(tester, option);

      // Save
      await CommonTest.tapByKey(
        tester,
        'menuItemUpdate',
        seconds: CommonTest.waitTime,
      );

      // Wait for dialog to close and list to update
      await tester.pumpAndSettle(const Duration(seconds: 2));

      createdOptions.add(option);
    }

    // Persist test data
    await PersistFunctions.persistTest(
      test.copyWith(menuOptions: createdOptions),
    );
  }

  /// Check that menu options were created correctly
  /// Calls selectMenuOptions for each option since list closes after viewing
  static Future<void> checkMenuOptions(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    // Navigate to menu config list
    await selectMenuOptions(tester);
    for (final option in test.menuOptions) {
      expect(
        find.text(option.title),
        findsWidgets,
        reason: 'Menu option "${option.title}" should be visible in list',
      );

      // tap to detail
      await CommonTest.tapByText(tester, option.title);

      // Verify title
      expect(
        CommonTest.getTextFormField('menuItemTitle'),
        equals(option.title),
        reason: 'Title should match',
      );

      // Verify route if set
      if (option.route != null && option.route!.isNotEmpty) {
        expect(
          CommonTest.getTextFormField('menuItemRoute'),
          equals(option.route),
          reason: 'Route should match',
        );

        // cancel option detail
        await CommonTest.tapByKey(tester, 'cancel');
      }
    }
    // Close dialog by pressing cancel
    await CommonTest.tapByKey(tester, 'cancel');
  }

  /// Update menu options with new data
  /// Calls selectMenuOptions for each update since list closes after saving
  static Future<void> updateMenuOptions(
    WidgetTester tester,
    List<MenuOption> updatedOptions,
  ) async {
    SaveTest test = await PersistFunctions.getTest();

    for (
      int i = 0;
      i < updatedOptions.length && i < test.menuOptions.length;
      i++
    ) {
      final oldOption = test.menuOptions[i];
      final newOption = updatedOptions[i];

      // Navigate to menu config list
      await selectMenuOptions(tester);

      // Find and tap the existing option
      await CommonTest.tapByText(tester, oldOption.title);

      // Clear and update the data
      await _enterMenuOptionData(tester, newOption);

      // Save
      await CommonTest.tapByKey(
        tester,
        'menuItemUpdate',
        seconds: CommonTest.waitTime,
      );

      // Wait for dialog to close
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Update persisted test data
    await PersistFunctions.persistTest(
      test.copyWith(menuOptions: updatedOptions),
    );
  }

  /// Delete the last menu option
  /// Calls selectMenuOptions first since list may be closed
  static Future<void> deleteLastMenuOption(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.menuOptions.isEmpty) return;

    final lastOption = test.menuOptions.last;

    // Find delete buttons
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsWidgets, reason: 'Should find delete buttons');

    // Tap the last delete button
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    // Confirm deletion
    await CommonTest.tapByText(tester, 'Delete');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify option is gone
    expect(
      find.text(lastOption.title),
      findsNothing,
      reason: 'Deleted option should no longer be visible',
    );

    // Update persisted test data
    await PersistFunctions.persistTest(
      test.copyWith(
        menuOptions: test.menuOptions.sublist(0, test.menuOptions.length - 1),
      ),
    );
  }

  /// Verify menu options persist after logout and login
  static Future<void> verifyMenuPersistence(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    // Close menu dialog if open
    await closeMenuOptions(tester);

    // Logout
    await CommonTest.logout(tester);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Login again
    await CommonTest.login(tester);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Navigate back to menu options
    await selectMenuOptions(tester);

    // Verify all options still exist
    for (final option in test.menuOptions) {
      expect(
        find.text(option.title),
        findsWidgets,
        reason:
            'Menu option "${option.title}" should persist after logout/login',
      );
    }

    debugPrint(
      'Verified ${test.menuOptions.length} menu options persist after logout/login',
    );
  }

  /// Reset menu to default configuration
  /// Calls selectMenuOptions first since list may be closed
  static Future<void> resetMenuToDefault(WidgetTester tester) async {
    // Navigate to menu config list
    await selectMenuOptions(tester);

    await CommonTest.tapByKey(
      tester,
      'resetMenuItemsFab',
      seconds: CommonTest.waitTime,
    );

    // Confirm reset
    await CommonTest.tapByText(tester, 'Reset');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    debugPrint('Menu reset to default configuration');
  }

  /// Close the menu options dialog
  static Future<void> closeMenuOptions(WidgetTester tester) async {
    // Try to close via cancel key or Navigator.pop
    if (await CommonTest.doesExistKey(tester, 'MenuItemListDialog')) {
      // Press Escape or tap outside to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }
  }

  // ==================== Helper methods ====================

  /// Enter menu option data into the form
  static Future<void> _enterMenuOptionData(
    WidgetTester tester,
    MenuOption option,
  ) async {
    // Title - clear first then enter
    await CommonTest.enterText(tester, 'menuItemTitle', option.title);

    // Route
    if (option.route != null) {
      await CommonTest.enterText(tester, 'menuItemRoute', option.route!);
    }

    // Icon (now Autocomplete, not dropdown)
    if (option.iconName != null) {
      await CommonTest.enterAutocompleteValue(
        tester,
        'menuItemIcon',
        option.iconName!,
      );
    }

    // Widget name (Autocomplete)
    if (option.widgetName != null) {
      await CommonTest.enterAutocompleteValue(
        tester,
        'menuItemWidget',
        option.widgetName!,
      );
    }

    // Sequence
    await CommonTest.enterText(
      tester,
      'menuItemSequence',
      option.sequenceNum.toString(),
    );

    // Active toggle - only toggle if different from default (true)
    if (!option.isActive) {
      await CommonTest.tapByKey(tester, 'menuItemActive');
    }
  }

  // ==================== Menu Item (Tab) Test Methods ====================

  /// Add menu items (tabs) to the first menu option
  /// Opens the first menu option, then adds each menu item via the "Add Tab" dialog
  static Future<void> addMenuItems(
    WidgetTester tester,
    List<MenuItem> menuItems,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.menuOptions.isEmpty) {
      debugPrint('Warning: No menu options to add tabs to');
      return;
    }

    // Tap on the first menu option to open detail
    final firstOption = test.menuOptions.first;

    // Add each menu item (tab)
    for (final menuItem in menuItems) {
      // Navigate to menu config list
      await selectMenuOptions(tester);
      // go to first option
      await CommonTest.tapByText(tester, firstOption.title);
      // Tap add tab button to open the Add Tab dialog
      await CommonTest.tapByKey(
        tester,
        'addTabButton',
        seconds: CommonTest.waitTime,
      );

      // Enter widget name via autocomplete - must select from suggestions
      // to trigger onSelected and set selectedWidget
      await CommonTest.enterAutocompleteValue(
        tester,
        'tabWidgetSelector',
        menuItem.widgetName!,
      );

      // Enter/confirm the tab title
      await CommonTest.enterText(tester, 'tabTitle', menuItem.title);

      // add by tapping Add button
      await CommonTest.tapByKey(
        tester,
        'addTabConfirm',
        seconds: CommonTest.waitTime,
      );

      debugPrint('Added menu item tab: ${menuItem.title}');
    }

    // currently adding a tab will always return to the main menu of the app

    // Update the first menu option with the new children
    // Navigate to menu config list
    await selectMenuOptions(tester);
    final updatedFirstOption = firstOption.copyWith(
      children: [...(firstOption.children ?? []), ...menuItems],
    );
    final updatedMenuOptions = [
      updatedFirstOption,
      ...test.menuOptions.skip(1),
    ];
    await PersistFunctions.persistTest(
      test.copyWith(menuOptions: updatedMenuOptions),
    );
  }

  /// Check that menu items (tabs) were added to the first added menu option
  static Future<void> checkMenuItems(
    WidgetTester tester,
    List<MenuItem> expectedItems,
  ) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.menuOptions.isEmpty) {
      debugPrint('Warning: No menu options to check tabs for');
      return;
    }

    // Navigate to menu config list
    await selectMenuOptions(tester);

    // Tap on the first menu option to open detail
    final firstOption = test.menuOptions.first;
    await CommonTest.tapByText(tester, firstOption.title);

    // Verify each expected menu item appears as a chip
    for (final menuItem in expectedItems) {
      await CommonTest.checkText(tester, menuItem.title);
      debugPrint('Verified menu item tab: ${menuItem.title}');
    }

    // Close the main menu
    await CommonTest.gotoMainMenu(tester);
  }

  /// Delete the last menu item (tab) from the first menu option
  static Future<void> deleteMenuItems(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.menuOptions.isEmpty) {
      debugPrint('Warning: No menu options to delete tabs from');
      return;
    }

    // Navigate to menu config list
    await selectMenuOptions(tester);

    // Tap on the first menu option to open detail
    final firstOption = test.menuOptions.first;
    await CommonTest.tapByText(tester, firstOption.title);

    // Find delete icons on chips (the small 'x' on each tab chip)
    // Chips use onDeleted which renders a close icon
    final deleteIcons = find.byIcon(Icons.close);

    if (tester.any(deleteIcons)) {
      // Tap the last delete icon (on the last tab)
      await tester.tap(deleteIcons.last);
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

      debugPrint('Deleted last menu item tab');
    } else {
      debugPrint('No tab delete icons found');
    }

    // Close the menu option detail dialog
    await CommonTest.tapByKey(tester, 'cancel');
  }
}
