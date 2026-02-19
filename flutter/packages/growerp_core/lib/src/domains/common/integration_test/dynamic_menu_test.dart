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
  /// Navigate to the Menu Item List Dialog via dashboard FAB.
  /// Safe to call even when the dialog is already open — skips tapping the FAB
  /// in that case and simply waits for the dialog to be ready.
  static Future<void> selectMenuItems(WidgetTester tester) async {
    // If the dialog is already open, skip tapping the FAB
    if (!tester.any(find.byKey(const Key('MenuItemListDialog')))) {
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

      // Wait for the MenuItemListDialog to appear (up to 10 seconds in headless)
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byKey(const Key('MenuItemListDialog')))) break;
      }
    }

    // Wait for loading to finish (up to 15 seconds in headless)
    for (int i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.any(find.byType(CircularProgressIndicator))) break;
    }
    // Extra pump to ensure all widgets are rendered
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Add menu options from the provided list
  /// Calls selectMenuItems before each add since list closes after saving
  static Future<void> addMenuItems(
    WidgetTester tester,
    List<MenuItem> menuItems,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    List<MenuItem> createdOptions = [];

    for (final option in menuItems) {
      // Navigate to menu config list (closes after each save)
      await selectMenuItems(tester);

      // Wait for the addMenuItemFab to be visible (up to 10 seconds in headless)
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byKey(const Key('addMenuItemFab')))) break;
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Tap add button
      await CommonTest.tapByKey(
        tester,
        'addMenuItemFab',
        seconds: CommonTest.waitTime,
      );

      // Enter menu option data
      await _enterMenuItemData(tester, option);

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
      test.copyWith(menuItems: createdOptions),
    );
  }

  /// Check that menu options were created correctly
  /// Calls selectMenuItems for each option since list closes after viewing
  static Future<void> checkMenuItems(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    // Navigate to menu config list
    await selectMenuItems(tester);
    // Wait for the first expected option to appear to avoid race conditions
    if (test.menuItems.isNotEmpty) {
      await _waitForText(tester, test.menuItems.first.title);
    }
    for (int idx = 0; idx < test.menuItems.length; idx++) {
      final option = test.menuItems[idx];

      // Scroll the item fully into view before tapping
      final textFinder = find.text(option.title);
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(textFinder)) break;
      }
      if (tester.any(textFinder)) {
        await tester.ensureVisible(textFinder.last);
        await tester.pumpAndSettle();
      }

      expect(
        textFinder,
        findsWidgets,
        reason: 'Menu option "${option.title}" should be visible in list',
      );

      // Tap the InkWell ancestor of the title text to open the detail dialog.
      // The text itself can be obscured by the ReorderableDragStartListener,
      // so tapping the InkWell (which wraps the whole card row) is more reliable.
      final inkWellFinder = find.ancestor(
        of: textFinder.last,
        matching: find.byType(InkWell),
      );
      for (int attempt = 0; attempt < 2; attempt++) {
        if (inkWellFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(inkWellFinder.first);
          await tester.pumpAndSettle();
          await tester.tap(inkWellFinder.first, warnIfMissed: false);
        } else {
          await tester.tap(textFinder.last, warnIfMissed: false);
        }
        bool opened = false;
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (tester.any(find.byKey(const Key('menuItemTitle')))) {
            opened = true;
            break;
          }
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        if (opened) break;
      }

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
  /// Currently updates only the first item to avoid dialog state issues during iteration
  /// Note: Scrolling logic has been added to checkMenuItems to handle visibility
  static Future<void> updateMenuItems(
    WidgetTester tester,
    List<MenuItem> updatedOptions,
  ) async {
    SaveTest test = await PersistFunctions.getTest();

    if (test.menuItems.isEmpty) {
      return;
    }

    for (
      int i = 0;
      i < 1 && i < updatedOptions.length && i < test.menuItems.length;
      i++
    ) {
      final oldOption = test.menuItems[i];
      final newOption = updatedOptions[i];

      // Navigate to menu config list
      await selectMenuItems(tester);

      // Wait for the dialog to fully render
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find and wait for the item to be visible
      await _waitForText(tester, oldOption.title, tries: 150);

      // Tap the option to open its detail dialog.
      // The text itself can be obscured by the ReorderableDragStartListener,
      // so tapping the InkWell ancestor (which wraps the whole card row) is
      // more reliable — same approach as checkMenuItems.
      final textFinder = find.textContaining(
        RegExp(oldOption.title, caseSensitive: false),
      );
      final inkWellFinder = find.ancestor(
        of: textFinder.last,
        matching: find.byType(InkWell),
      );
      bool opened = false;
      for (int attempt = 0; attempt < 2; attempt++) {
        if (inkWellFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(inkWellFinder.first);
          await tester.pumpAndSettle();
          await tester.tap(inkWellFinder.first, warnIfMissed: false);
        } else {
          await tester.ensureVisible(textFinder.last);
          await tester.pumpAndSettle();
          await tester.tap(textFinder.last, warnIfMissed: false);
        }
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (tester.any(find.byKey(const Key('menuItemTitle')))) {
            opened = true;
            break;
          }
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        if (opened) break;
      }
      expect(opened, true, reason: 'Menu item detail dialog did not open');

      // Clear and update the data
      await _enterMenuItemData(tester, newOption);

      // Save by tapping update button
      await CommonTest.tapByKey(
        tester,
        'menuItemUpdate',
        seconds: CommonTest.waitTime,
      );

      // Wait for dialogs to close and BLoC to update
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Update test data
      test = test.copyWith(
        menuItems: [
          for (int j = 0; j < test.menuItems.length; j++)
            if (j == i) newOption else test.menuItems[j],
        ],
      );
      await PersistFunctions.persistTest(test);
    }

    // Update persisted test data with first updated option
    await PersistFunctions.persistTest(
      test.copyWith(
        menuItems: [
          if (updatedOptions.isNotEmpty) updatedOptions[0],
          ...test.menuItems.sublist(1),
        ],
      ),
    );
  }

  /// Utility: wait until a specific text appears (or timeout)
  static Future<void> _waitForText(
    WidgetTester tester,
    String text, {
    int tries = 100,
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    for (int i = 0; i < tries; i++) {
      await tester.pump(interval);
      if (tester.any(find.textContaining(RegExp(text, caseSensitive: false)))) {
        return;
      }
    }
  }

  /// Delete the first menu option
  /// Deletes from the top of the list to avoid FABs positioned at the bottom
  /// covering the delete buttons of lower items.
  /// Calls selectMenuItems first since list may be closed
  static Future<void> deleteLastMenuItem(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.menuItems.isEmpty) return;

    // Navigate to menu config list first to ensure it's open
    await selectMenuItems(tester);

    // Wait for the first delete button to be visible (top of list, not covered by FABs)
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byIcon(Icons.delete_outline))) break;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Delete the first item (at the top) to avoid FAB overlap at the bottom
    final firstOption = test.menuItems.first;

    // Find delete buttons
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsWidgets, reason: 'Should find delete buttons');

    // Tap the first delete button (top of list, away from FABs)
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    // Confirm deletion
    await CommonTest.tapByText(tester, 'Delete');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify option is gone
    expect(
      find.text(firstOption.title),
      findsNothing,
      reason: 'Deleted option should no longer be visible',
    );

    // Update persisted test data
    await PersistFunctions.persistTest(
      test.copyWith(menuItems: test.menuItems.sublist(1)),
    );
  }

  /// Verify menu options persist after logout and login
  static Future<void> verifyMenuPersistence(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    // Close menu dialog if open
    await closeMenuItems(tester);

    // Logout
    await CommonTest.logout(tester);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Login again
    await CommonTest.login(tester);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Navigate back to menu options
    await selectMenuItems(tester);

    // Verify all options still exist
    for (int idx = 0; idx < test.menuItems.length; idx++) {
      final option = test.menuItems[idx];

      // Scroll to make sure item is visible
      if (idx > 0) {
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -200));
          await tester.pumpAndSettle();
        }
      }

      expect(
        find.text(option.title),
        findsWidgets,
        reason:
            'Menu option "${option.title}" should persist after logout/login',
      );
    }

    debugPrint(
      'Verified ${test.menuItems.length} menu options persist after logout/login',
    );
  }

  /// Reset menu to default configuration
  /// Calls selectMenuItems first since list may be closed
  static Future<void> resetMenuToDefault(WidgetTester tester) async {
    // Navigate to menu config list
    await selectMenuItems(tester);

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
  static Future<void> closeMenuItems(WidgetTester tester) async {
    // Close the dialog using the cancel button if it's visible
    if (await CommonTest.doesExistKey(tester, 'cancel')) {
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  // ==================== Helper methods ====================

  /// Enter menu option data into the form
  static Future<void> _enterMenuItemData(
    WidgetTester tester,
    MenuItem option,
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

  // ==================== Child Menu Item (Tab) Test Methods ====================

  /// Add child menu items (tabs) to the first menu item
  /// Opens the first menu item, then adds each child via the "Add Tab" dialog
  static Future<void> addChildMenuItems(
    WidgetTester tester,
    List<MenuItem> childMenuItems,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.menuItems.isEmpty) {
      debugPrint('Warning: No menu options to add tabs to');
      return;
    }

    // Tap on the first menu option to open detail
    final firstOption = test.menuItems.first;

    // Add each child menu item (tab)
    for (final menuItem in childMenuItems) {
      // Navigate to menu config list
      await selectMenuItems(tester);
      // go to first option
      await CommonTest.tapByText(tester, firstOption.title);

      // Wait for the add tab button to be visible
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byKey(const Key('addTabButton')))) break;
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

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
    final updatedFirstOption = firstOption.copyWith(
      children: [...(firstOption.children ?? []), ...childMenuItems],
    );
    final updatedMenuItemsList = [
      updatedFirstOption,
      ...test.menuItems.skip(1),
    ];
    await PersistFunctions.persistTest(
      test.copyWith(menuItems: updatedMenuItemsList),
    );

    // Ensure we're back on the main menu (no dialogs open)
    await CommonTest.gotoMainMenu(tester);
  }

  /// Check that child menu items (tabs) were added to the first menu item
  static Future<void> checkChildMenuItems(
    WidgetTester tester,
    List<MenuItem> expectedItems,
  ) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.menuItems.isEmpty) {
      debugPrint('Warning: No menu options to check tabs for');
      return;
    }

    // Navigate to menu config list
    await selectMenuItems(tester);

    // Tap on the first menu option to open detail
    final firstOption = test.menuItems.first;
    await CommonTest.tapByText(tester, firstOption.title);

    // Verify each expected menu item appears as a chip
    for (final menuItem in expectedItems) {
      await CommonTest.checkText(tester, menuItem.title);
      debugPrint('Verified menu item tab: ${menuItem.title}');
    }

    // Close the detail dialog first
    await CommonTest.tapByKey(tester, 'cancel');

    // Close the menu list dialog
    await closeMenuItems(tester);

    // Ensure we're back on the main menu
    await CommonTest.gotoMainMenu(tester);
  }

  /// Delete the last child menu item (tab) from the first menu item
  static Future<void> deleteChildMenuItems(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    if (test.menuItems.isEmpty) {
      debugPrint('Warning: No menu options to delete tabs from');
      return;
    }

    // Navigate to menu config list
    await selectMenuItems(tester);

    // Tap on the first menu option to open detail
    final firstOption = test.menuItems.first;
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

    // Close the menu list dialog
    await closeMenuItems(tester);

    // Ensure we're back on the main menu
    await CommonTest.gotoMainMenu(tester);
  }
}
