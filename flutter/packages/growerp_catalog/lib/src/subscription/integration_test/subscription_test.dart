/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

class SubscriptionTest {
  static Future<void> selectSubscriptions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCatalog', 'SubscriptionList', '2');
  }

  static Future<void> addSubscriptions(
      WidgetTester tester, List<Subscription> subscriptions,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.subscriptions.isEmpty) {
      // not yet created
      await enterSubscriptionData(tester, subscriptions);
      await PersistFunctions.persistTest(
          test.copyWith(subscriptions: subscriptions));
    }
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          subscriptions: await checkSubscriptionDetail(tester, subscriptions)));
    }
  }

  static Future<void> updateSubscriptions(
      WidgetTester tester, List<Subscription> subscriptions) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Subscription> newSubscriptions = List.of(test.subscriptions);
    if (newSubscriptions.isNotEmpty &&
        newSubscriptions[0].description != subscriptions[0].description) {
      for (int x = 0; x < newSubscriptions.length; x++) {
        newSubscriptions[x] = subscriptions[x]
            .copyWith(subscriptionId: newSubscriptions[x].subscriptionId);
      }
      await enterSubscriptionData(tester, newSubscriptions);
      await PersistFunctions.persistTest(
          test.copyWith(subscriptions: newSubscriptions));
    }
    await checkSubscriptionDetail(tester, newSubscriptions);
  }

  static Future<void> deleteLastSubscription(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'subscriptionItem');
    if (count == (test.subscriptions.length)) {
      await CommonTest.gotoMainMenu(tester);
      await selectSubscriptions(tester);
      await CommonTest.tapByKey(tester, 'delete${count - 1}',
          seconds: CommonTest.waitTime);
      await CommonTest.gotoMainMenu(tester);
      await selectSubscriptions(tester);
      expect(
          find.byKey(const Key('subscriptionItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          subscriptions:
              test.subscriptions.sublist(0, (test.subscriptions.length) - 1)));
    }
  }

  static Future<void> enterSubscriptionData(
      WidgetTester tester, List<Subscription> subscriptions) async {
    for (Subscription subscription in subscriptions) {
      if (subscription.subscriptionId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester,
            searchString: subscription.subscriptionId!);
        await CommonTest.tapByKey(tester, 'code0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            subscription.subscriptionId);
      }
      await CommonTest.checkWidgetKey(tester, 'SubscriptionDialog');
      await CommonTest.enterText(
          tester, 'pseudoId', subscription.pseudoId ?? '');
      await CommonTest.enterText(
          tester, 'description', subscription.description ?? '');
      await CommonTest.enterText(
          tester, 'fromDate', subscription.fromDate?.toString() ?? '');
      await CommonTest.enterText(
          tester, 'thruDate', subscription.thruDate?.toString() ?? '');
      // Add more fields as needed
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.checkWidgetKey(tester, 'SubscriptionList');
    }
  }

  static Future<List<Subscription>> checkSubscriptionDetail(
      WidgetTester tester, List<Subscription> subscriptions) async {
    List<Subscription> checked = [];
    for (int i = 0; i < subscriptions.length; i++) {
      await CommonTest.doSearch(tester,
          searchString: subscriptions[i].pseudoId ?? '');
      await CommonTest.tapByKey(tester, 'code0');
      await CommonTest.checkWidgetKey(tester, 'SubscriptionDialog');
      // Optionally check fields here
      checked.add(subscriptions[i]);
      await CommonTest.tapByKey(tester, 'cancel');
      await CommonTest.checkWidgetKey(tester, 'SubscriptionList');
    }
    return checked;
  }
}
