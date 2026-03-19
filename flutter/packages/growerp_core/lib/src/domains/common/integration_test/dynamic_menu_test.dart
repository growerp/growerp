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

      // Save — same reasoning as updateMenuItems: avoid pumpAndSettle so the
      // HTTP backend round-trip has time to complete before we proceed.
      await CommonTest.tapByKey(
        tester,
        'menuItemUpdate',
        settle: false,
        seconds: 1,
      );

      // Wait for the MenuItemDialog to close (up to 15 s for backend round-trip)
      for (int i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byKey(const Key('MenuItemDialog')))) break;
      }

      // Wait for the new item to appear in the list
      await _waitForText(tester, option.title, tries: 100);

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

      // Save by tapping update button. Do NOT pumpAndSettle here — HTTP
      // responses are not tracked by the scheduler, so pumpAndSettle can
      // settle before the backend round-trip completes and the dialog closes.
      await CommonTest.tapByKey(
        tester,
        'menuItemUpdate',
        settle: false,
        seconds: 1,
      );

      // Wait for the MenuItemDialog to close (up to 15 s for backend round-trip)
      for (int i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byKey(const Key('MenuItemDialog')))) break;
      }

      // Explicitly clear the REST cache so the next getMenuConfiguration
      // GET is guaranteed to hit the backend and not a stale cached entry.
      // The CacheInvalidationInterceptor fires on PATCH but its async void
      // clean() may race against the immediately-following GET in the BLoC.
      await clearRestCache();

      // Wait for the updated title to appear in the list
      await _waitForText(tester, newOption.title, tries: 100);

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

  /// Delete a menu option
  /// Deletes the second item from the top of the list
  /// Calls selectMenuItems first since list may be closed
  static Future<void> deleteMenuItem(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.menuItems.length < 2) return;

    // Navigate to menu config list first to ensure it's open
    await selectMenuItems(tester);

    // Wait for the first delete button to be visible (top of list, not covered by FABs)
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byIcon(Icons.delete_outline))) break;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Find delete buttons
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsWidgets, reason: 'Should find delete buttons');

    // Before tapping, capture the actual title displayed in the second card row
    // so we verify the right item is gone — regardless of whether the UI order
    // matches the persisted test.menuItems order.
    String? uiTargetTitle;
    {
      final secondDeleteElement = tester.element(deleteButtons.at(1));
      Element? cardElement;
      secondDeleteElement.visitAncestorElements((ancestor) {
        if (ancestor.widget is Card) {
          cardElement = ancestor;
          return false;
        }
        return true;
      });
      if (cardElement != null) {
        final cardFinder = find.byElementPredicate((el) => el == cardElement);
        // The title Text has fontWeight bold; collect all Text descendants and
        // pick the first one with non-empty data (skipping icon-label texts).
        final texts = find.descendant(
          of: cardFinder,
          matching: find.byType(Text),
        );
        for (int i = 0; i < texts.evaluate().length; i++) {
          final t = tester.widget<Text>(texts.at(i));
          if (t.data != null && t.data!.isNotEmpty) {
            uiTargetTitle = t.data;
            break;
          }
        }
      }
    }
    // Fall back to persisted data if we couldn't read the UI title.
    uiTargetTitle ??= test.menuItems[1].title;

    // Tap the second delete button
    await tester.tap(deleteButtons.at(1));
    await tester.pumpAndSettle();

    // Confirm deletion — use settle:false so the HTTP DELETE + reload has time
    // to complete before we pump to settled (same pattern as addMenuItems/updateMenuItems).
    await CommonTest.tapByText(tester, 'Delete');
    // Clear the REST cache so the next GET bypasses any stale cached entry,
    // just like updateMenuItems does after a PATCH round-trip.
    await clearRestCache();
    // Wait up to 15 s for the backend to process the delete and the list to refresh.
    // Scope the check to the MenuItemListDialog so the navigation rail (which
    // still shows the old menu until a full reload) does not cause a false
    // "still found" result.
    final listDialogFinder = find.byKey(const Key('MenuItemListDialog'));
    for (int i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final inDialog = tester.any(listDialogFinder)
          ? tester.any(
              find.descendant(
                of: listDialogFinder,
                matching: find.text(uiTargetTitle),
              ),
            )
          : false;
      if (!inDialog) break;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Verify the item that was actually shown in slot 2 is now gone from the list.
    expect(
      find.descendant(
        of: find.byKey(const Key('MenuItemListDialog')),
        matching: find.text(uiTargetTitle),
      ),
      findsNothing,
      reason:
          'Deleted option "$uiTargetTitle" should no longer be visible in the list',
    );

    // Update persisted test data
    await PersistFunctions.persistTest(
      test.copyWith(menuItems: [test.menuItems[0], ...test.menuItems.skip(2)]),
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

  /// Verify that menu customizations made by one company are not visible to a
  /// different company's users.
  ///
  /// 1. Logs out of the current session.
  /// 2. Creates a brand-new company with a fresh admin user.
  /// 3. Waits for the menu to reload (handled by TopApp's auth listener).
  /// 4. Opens the menu config dialog and asserts that none of [titlesNotExpected]
  ///    appear — they belong to the first company and must remain isolated.
  /// 5. Logs out from the new company, restores the original test state, and
  ///    logs back into the first company so the test can continue.
  static Future<void> verifyMenuIsolation(
    WidgetTester tester,
    List<String> titlesNotExpected,
  ) async {
    // Save state so we can restore Company A's session afterwards.
    final SaveTest savedTest = await PersistFunctions.getTest();

    // Close the menu dialog if open, then log out of Company A.
    await closeMenuItems(tester);
    await CommonTest.logout(tester);

    // Reset persisted test state (keep sequence so email addresses stay unique)
    // but clear admin so createCompanyAndAdmin creates a new company.
    await PersistFunctions.persistTest(SaveTest(sequence: savedTest.sequence));

    // Register and log in as a brand-new company (Company B).
    await CommonTest.createCompanyAndAdmin(tester);

    // Wait for the menu to reload for the new user (TopApp triggers MenuConfigLoad
    // automatically on authentication).
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.any(find.byType(CircularProgressIndicator))) break;
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Open the menu config dialog.
    await selectMenuItems(tester);

    // Verify Company A's custom menu items are NOT present for Company B.
    for (final title in titlesNotExpected) {
      expect(
        find.text(title),
        findsNothing,
        reason:
            'Menu item "$title" from a different company should not be visible '
            'to a new company user',
      );
    }

    await closeMenuItems(tester);

    // Log out of Company B, restore Company A's state and log back in.
    await CommonTest.logout(tester);
    await PersistFunctions.persistTest(savedTest);
    await CommonTest.login(tester);

    // Wait for Company A's menu to reload.
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.any(find.byType(CircularProgressIndicator))) break;
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));
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
    // Title
    await CommonTest.enterText(tester, 'menuItemTitle', option.title);

    // Icon (Autocomplete). Note: the widget-name autocomplete's onSelected
    // auto-fills the route field from the widget name when route is empty.
    // We therefore enter route LAST, after all autocomplete interactions.
    if (option.iconName != null) {
      await CommonTest.enterAutocompleteValue(
        tester,
        'menuItemIcon',
        option.iconName!,
      );
    }

    // Widget name (Autocomplete). onSelected may overwrite route if empty.
    if (option.widgetName != null) {
      await CommonTest.enterAutocompleteValue(
        tester,
        'menuItemWidget',
        option.widgetName!,
      );
    }

    // Sequence — entered before route so the route field is the very last
    // thing touched and cannot be overwritten by subsequent autocomplete events.
    await CommonTest.enterText(
      tester,
      'menuItemSequence',
      option.sequenceNum.toString(),
    );

    // Active toggle - only toggle if different from default (true)
    if (!option.isActive) {
      await CommonTest.tapByKey(tester, 'menuItemActive');
    }

    // Route — entered LAST so the widget autocomplete's onSelected auto-fill
    // (which sets route from widget name when route is empty) cannot overwrite
    // it.  Use CommonTest.enterText (which calls pumpAndSettle) so the
    // TextEditingController is reliably updated before the form is saved.
    if (option.route != null) {
      await CommonTest.enterText(tester, 'menuItemRoute', option.route!);
      // Verify the route was set correctly; re-enter once if still wrong.
      final actual = CommonTest.getTextFormField('menuItemRoute');
      if (actual != option.route) {
        await CommonTest.enterText(tester, 'menuItemRoute', option.route!);
      }
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
      // to trigger onSelected and set selectedWidget.
      await CommonTest.enterAutocompleteValue(
        tester,
        'tabWidgetSelector',
        menuItem.widgetName!,
      );

      // Enter/confirm the tab title AFTER the autocomplete so that even if
      // onSelected auto-filled the title from the widget name, we overwrite
      // it with the correct value — same pattern as the route field.
      await CommonTest.enterText(tester, 'tabTitle', menuItem.title);

      // add by tapping Add button. Use settle:false — HTTP responses are not
      // tracked by the scheduler, so pumpAndSettle can settle before the
      // backend POST completes and the tab appears in the parent item.
      await CommonTest.tapByKey(
        tester,
        'addTabConfirm',
        settle: false,
        seconds: 1,
      );

      // Wait for the add tab dialog to close (navigator pops it synchronously
      // after tapping confirm, but we still need pumps for the frame to render).
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byKey(const Key('addTabDialog')))) break;
      }

      // Wait for the MenuItemLink BLoC event to complete (POST + backend reload).
      // With the buildWhen fix in CoreApp the router is no longer recreated on
      // every BLoC emission, so the dialogs stay open.  We simply wait until the
      // CircularProgressIndicator (loading state) disappears (up to 15 s).
      for (int i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byType(CircularProgressIndicator))) break;
      }

      debugPrint('Added menu item tab: ${menuItem.title}');
    }

    // After all tabs are added the dialogs are still open (the buildWhen fix
    // in CoreApp prevents router recreation on tab CRUD, so navigation is not
    // reset).  Update persisted test state with the expected children.
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

    // Close any MenuItemDialog left open by a previous step (e.g. addChildMenuItems
    // leaves it open).  Tapping its title text did nothing; we need a fresh open so
    // the dialog rebuilds with the current BLoC state (all tabs present).
    if (tester.any(find.byKey(const Key('MenuItemDialog')))) {
      await CommonTest.tapByKey(tester, 'cancel');
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byKey(const Key('MenuItemDialog')))) break;
      }
    }

    // Tap on the first menu option to open the dialog fresh.
    final firstOption = test.menuItems.first;
    await CommonTest.tapByText(tester, firstOption.title, seconds: 1);

    // Wait for any loading state to finish before checking tabs.
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.any(find.byType(CircularProgressIndicator)) &&
          !tester.any(find.byType(LoadingIndicator))) {
        break;
      }
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Wait up to 10 s for the first expected tab to appear in the form.
    if (expectedItems.isNotEmpty) {
      await _waitForText(tester, expectedItems.first.title, tries: 100);
    }

    // Verify each expected menu item appears as a list tile in the dialog
    await CommonTest.drag(tester);
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
