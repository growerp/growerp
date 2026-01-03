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
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class SubscriptionTest {
  static Future<void> selectSubscriptions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/subscriptions', 'SubscriptionList');
  }

  static Future<void> addSubscriptions(
    WidgetTester tester,
    List<Subscription> subscriptions, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.subscriptions.isEmpty) {
      // not yet created
      await PersistFunctions.persistTest(
        SaveTest(subscriptions: subscriptions),
      );
      await enterSubscriptionData(tester);
    }
    if (check) {
      await checkSubscriptionDetail(tester);
    }
  }

  static Future<void> updateSubscriptions(
    WidgetTester tester,
    List<Subscription> newSubscriptions,
  ) async {
    List<Subscription> subscriptions =
        (await PersistFunctions.getTest()).subscriptions;
    // copy over pseudoId
    if (newSubscriptions.isNotEmpty) {
      for (int x = 0; x < newSubscriptions.length; x++) {
        newSubscriptions[x] = newSubscriptions[x].copyWith(
          pseudoId: subscriptions[x].pseudoId,
        );
      }
      await PersistFunctions.persistTest(
        SaveTest(subscriptions: newSubscriptions),
      );
      await enterSubscriptionData(tester);
    }
    await checkSubscriptionDetail(tester);
  }

  static Future<void> deleteLastSubscription(WidgetTester tester) async {
    List<Subscription> subscriptions =
        (await PersistFunctions.getTest()).subscriptions;
    var count = CommonTest.getWidgetCountByKey(tester, 'subscriptionItem');
    if (count == (subscriptions.length)) {
      await CommonTest.gotoMainMenu(tester);
      await selectSubscriptions(tester);
      await CommonTest.tapByKey(
        tester,
        'delete${count - 1}',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.gotoMainMenu(tester);
      await selectSubscriptions(tester);
      expect(
        find.byKey(const Key('subscriptionItem')),
        findsNWidgets(count - 1),
      );
      await PersistFunctions.persistTest(
        SaveTest(
          subscriptions: subscriptions.sublist(0, (subscriptions.length) - 1),
        ),
      );
    }
  }

  static Future<void> enterSubscriptionData(WidgetTester tester) async {
    List<Subscription> subscriptions =
        (await PersistFunctions.getTest()).subscriptions;
    List<Subscription> subscriptionsWithPseudoId = [];
    for (Subscription subscription in subscriptions) {
      if (subscription.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: subscription.pseudoId!,
        );
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          subscription.pseudoId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'SubscriptionDialog');
      await CommonTest.enterText(
        tester,
        'pseudoId',
        subscription.pseudoId ?? '',
      );
      await CommonTest.enterText(
        tester,
        'description',
        subscription.description ?? '',
      );
      if (subscription.fromDate != null) {
        await CommonTest.enterDate(
          tester,
          'fromDate',
          subscription.fromDate!,
          usDate: true,
        );
      }
      if (subscription.thruDate != null) {
        await CommonTest.enterDate(
          tester,
          'thruDate',
          subscription.thruDate!,
          usDate: true,
        );
      }
      await CommonTest.enterDropDownSearch(
        tester,
        'subscriber',
        subscription.subscriber!.name!,
      );
      await CommonTest.enterDropDownSearch(
        tester,
        'product',
        subscription.product!.productName!,
      );
      // Add more fields as needed
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
      await CommonTest.checkWidgetKey(tester, 'SubscriptionList');
      // new items always added at the top
      subscriptionsWithPseudoId.add(
        subscription.copyWith(pseudoId: CommonTest.getTextField('id0')),
      );
    }
    // only update when pseudoId was missing
    if (subscriptions[0].pseudoId == null) {
      await PersistFunctions.persistTest(
        SaveTest(subscriptions: subscriptionsWithPseudoId),
      );
    }
  }

  static Future<void> checkSubscriptionDetail(WidgetTester tester) async {
    List<Subscription> subscriptions =
        (await PersistFunctions.getTest()).subscriptions;

    for (var subscription in subscriptions) {
      await CommonTest.doNewSearch(
        tester,
        searchString: subscription.pseudoId!,
      );
      await CommonTest.checkWidgetKey(tester, 'SubscriptionDialog');

      // Get the FormBuilder state for all fields including dropdowns
      final formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );
      formState.save(); // save into the formbuilder internal value fields

      if (subscription.fromDate != null) {
        expect(
          (formState.value['fromDate'] as DateTime).dateOnly(),
          subscription.fromDate.dateOnly(),
        );
      }
      if (subscription.thruDate != null) {
        expect(
          (formState.value['thruDate'] as DateTime).dateOnly(),
          subscription.thruDate.dateOnly(),
        );
      }

      // Check FormBuilder text fields
      expect(formState.value['description'], subscription.description);

      // Now we can check the FormBuilder dropdown values
      if (subscription.product != null) {
        final formProduct = formState.value['product'] as Product?;
        if (formProduct != null) {
          expect(formProduct.productName, subscription.product!.productName);
        }
      }
      if (subscription.subscriber != null) {
        final formSubscriber = formState.value['subscriber'] as CompanyUser?;
        if (formSubscriber != null) {
          expect(formSubscriber.name, subscription.subscriber!.name);
        }
      }

      await CommonTest.tapByKey(tester, 'cancel');
      await CommonTest.checkWidgetKey(tester, 'SubscriptionList');
    }
  }
}
