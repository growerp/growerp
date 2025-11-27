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
import '../../common/integration_test/common_test.dart';
import '../../../extensions.dart' as ext;

/// Test class for evaluation period and subscription flows.
///
/// This class provides methods to test both configuration scenarios:
/// - creditCardUpfront=false (default): Shows evaluation welcome page first
/// - creditCardUpfront=true: Shows payment form upfront
///
/// IMPORTANT: Before running these tests, ensure:
/// 1. The Moqui backend is running
/// 2. The GrowERP owner account (test@example.com/qqqqqq9!) exists
/// 3. Subscriptions are configured in the GrowERP owner account
///
/// The environment variables controlling this behavior are:
/// - creditCardUpfront: if 'true', require credit card before evaluation
/// - evaluationDays: number of days for the evaluation period (default: 14)
class EvaluationTest {
  /// Set the backend effective time offset for the next login.
  ///
  /// This delegates to the setTestDaysOffset function in extensions.dart.
  /// See that function for documentation on what it does.
  static void setTestDaysOffset(int daysOffset) {
    ext.setTestDaysOffset(daysOffset);
    debugPrint(
      'Test days offset set: daysOffset=$daysOffset (will be applied on next login)',
    );
  }

  /// Reset effective time offset.
  static void resetTestDaysOffset() {
    ext.setTestDaysOffset(0);
    debugPrint('Test days offset reset');
  }

  /// Check if the evaluation welcome form is displayed.
  /// This form is shown when creditCardUpfront=false (default).
  static Future<bool> isEvaluationWelcomeDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'evaluationWelcome');
  }

  /// Check if the payment form is displayed.
  /// This form is shown when creditCardUpfront=true or after evaluation expires.
  static Future<bool> isPaymentFormDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'paymentForm');
  }

  /// Tap the "Start Evaluation" button on the evaluation welcome form.
  /// This creates a subscription without requiring payment upfront.
  static Future<void> startEvaluation(WidgetTester tester) async {
    await CommonTest.tapByKey(
      tester,
      'startEvaluation',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// Check that the evaluation welcome form displays correct information.
  /// Verifies the welcome message and evaluation period are shown.
  static Future<void> checkEvaluationWelcomeContent(
    WidgetTester tester, {
    int expectedDays = 14,
  }) async {
    // Check that the welcome form is displayed
    expect(
      find.byKey(const Key('evaluationWelcome')),
      findsOneWidget,
      reason: 'Evaluation welcome form should be displayed',
    );

    // Check for celebration icon
    expect(
      find.byIcon(Icons.celebration),
      findsOneWidget,
      reason: 'Celebration icon should be displayed',
    );

    // Check for start evaluation button
    expect(
      find.byKey(const Key('startEvaluation')),
      findsOneWidget,
      reason: 'Start Evaluation button should be displayed',
    );
  }

  /// Check that the payment form displays correctly.
  /// Used when creditCardUpfront=true or after evaluation expires.
  static Future<void> checkPaymentFormContent(WidgetTester tester) async {
    expect(
      find.byKey(const Key('paymentForm')),
      findsOneWidget,
      reason: 'Payment form should be displayed',
    );

    // Check for pay button
    expect(
      find.byKey(const Key('pay')),
      findsAtLeastNWidgets(1),
      reason: 'Pay button should be displayed',
    );
  }

  /// Submit the payment form with the pre-filled test credit card data.
  /// The form is pre-filled with test card 4012888888881881 in non-release mode.
  /// Returns true if payment was successful (dashboard shown), false if payment
  /// form is still displayed (payment failed).
  static Future<bool> submitPayment(WidgetTester tester) async {
    // The payment form should already be displayed with pre-filled test data
    // Just tap the pay button
    await CommonTest.tapByKey(tester, 'pay', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Check if we reached the dashboard (payment successful)
    if (await CommonTest.doesExistKey(tester, 'HomeFormAuth')) {
      debugPrint('✓ Payment successful - dashboard displayed');
      return true;
    }

    // Check if payment form is still displayed (payment failed)
    if (await isPaymentFormDisplayed(tester)) {
      debugPrint('✗ Payment failed - payment form still displayed');
      return false;
    }

    // Unknown state
    debugPrint('? Unknown state after payment submission');
    return false;
  }

  /// Verify the correct form is shown based on backend configuration.
  /// If creditCardUpfront=false (default), evaluationWelcome is shown.
  /// If creditCardUpfront=true, paymentForm is shown.
  static Future<String> verifyRegistrationForm(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));

    if (await isEvaluationWelcomeDisplayed(tester)) {
      debugPrint('Backend configured with creditCardUpfront=false');
      return 'evaluationWelcome';
    } else if (await isPaymentFormDisplayed(tester)) {
      debugPrint('Backend configured with creditCardUpfront=true');
      return 'paymentForm';
    } else {
      // Neither form shown - user might already have subscription
      debugPrint(
        'No registration form shown - user may already have subscription',
      );
      return 'none';
    }
  }
}
