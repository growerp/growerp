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
import 'package:growerp_models/growerp_models.dart';
import '../../common/integration_test/common_test.dart';

/// Test helper class for authentication-related integration tests.
///
/// Provides high-level and low-level test methods for:
/// - User registration (admin and non-admin)
/// - Login/logout flows
/// - Password change/reset
/// - Tenant setup
/// - Trial welcome handling
/// - Payment/subscription flows
class AuthTest {
  //===============================high level tests ============================

  /// Create a new admin user and company.
  ///
  /// This is the full registration flow for a new admin:
  /// 1. Opens registration form
  /// 2. Fills in user details
  /// 3. Submits registration
  /// 4. Does NOT login (use [login] after this method)
  static Future<void> createNewAdminAndCompany(
    WidgetTester tester,
    User user,
    Company company,
  ) async {
    await CommonTest.logout(tester);
    await CommonTest.checkText(tester, 'Login / New company'); // initial screen
    await pressNewCompany(tester);
    await enterFirstName(tester, user.firstName!);
    await enterLastname(tester, user.lastName!);
    await enterEmailAddress(tester, user.email!);
    await enterCompanyName(tester, user.company!.name!);
    await enterCurrency(tester, company.currency!);
    await CommonTest.drag(tester, seconds: 10);
    await clearDemoData(tester);
    await CommonTest.drag(tester, seconds: CommonTest.waitTime);
    await CommonTest.tapByKey(
      tester,
      'newCompany',
      seconds: CommonTest.waitTime,
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle();
  }

  /// Login with existing credentials.
  ///
  /// Navigates to login form, enters credentials, and submits.
  /// Verifies that dashboard is reached after successful login.
  static Future<void> login(
    WidgetTester tester,
    String loginName,
    String password,
  ) async {
    await pressLoginWithExistingId(tester);
    await enterLoginName(tester, loginName);
    await enterPassword(tester, password);
    await pressLogin(tester);
    await CommonTest.checkText(tester, 'Main'); // dashboard
  }

  /// Login only if not already authenticated.
  static Future<void> loginIfRequired(
    WidgetTester tester,
    String loginName,
    String password,
  ) async {
    try {
      expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);
    } catch (_) {
      await login(tester, loginName, password);
    }
  }

  /// Register a new admin user (opens registration, fills form).
  ///
  /// Returns the email address used for registration.
  static Future<String> registerNewAdmin(
    WidgetTester tester, {
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await CommonTest.tapByKey(tester, 'newUserButton');
    await enterFirstName(tester, firstName);
    await enterLastname(tester, lastName);
    await enterEmailAddress(tester, email);
    await CommonTest.tapByKey(
      tester,
      'newUserButton',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    return email;
  }

  /// Complete the tenant setup dialog.
  ///
  /// This fills in company name, currency, and demo data preference.
  static Future<void> completeTenantSetup(
    WidgetTester tester, {
    required String companyName,
    required Currency currency,
    bool demoData = false,
  }) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Check for TenantSetupDialog (new flow) or moreInfo form (legacy)
    if (await CommonTest.doesExistKey(tester, 'companyName')) {
      await CommonTest.enterText(tester, 'companyName', companyName);
      await CommonTest.enterDropDown(tester, 'currency', currency.description!);

      // Toggle demo data if currently different from desired state
      // (checkbox starts as true in debug mode)
      if (!demoData) {
        await CommonTest.tapByKey(tester, 'demoData');
      }

      // Submit - try 'submit' key first (TenantSetupDialog), then 'continue' (legacy)
      if (await CommonTest.doesExistKey(tester, 'submit')) {
        await CommonTest.tapByKey(
          tester,
          'submit',
          seconds: CommonTest.waitTime,
        );
      } else if (await CommonTest.doesExistKey(tester, 'continue')) {
        await CommonTest.tapByKey(
          tester,
          'continue',
          seconds: CommonTest.waitTime,
        );
      }

      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  /// Complete the entire post-login authentication flow.
  ///
  /// This handles all possible dialogs that may appear after login:
  /// - TrialWelcomeDialog (startTrial) → opens TenantSetupDialog
  /// - TenantSetupDialog (submit/cancel)
  /// - Legacy moreInfo form (continue)
  /// - EvaluationWelcome (startEvaluation)
  /// - TrialWelcomeHelper dialog (getStarted)
  ///
  /// Loops until dashboard is reached or max attempts exceeded.
  static Future<bool> completeAuthenticationFlow(
    WidgetTester tester, {
    required String companyName,
    required Currency currency,
    bool demoData = false,
    int maxAttempts = 10,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check for TrialWelcomeDialog - has 'startTrial' button
      if (await CommonTest.doesExistKey(tester, 'startTrial')) {
        debugPrint(
          'AuthTest: TrialWelcomeDialog detected, clicking startTrial...',
        );
        await CommonTest.tapByKey(tester, 'startTrial');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        continue; // Loop to handle TenantSetupDialog that follows
      }

      // Check for TenantSetupDialog (has 'submit' and 'companyName')
      if (await isTenantSetupDisplayed(tester)) {
        debugPrint('AuthTest: TenantSetupDialog detected, completing...');
        await completeTenantSetup(
          tester,
          companyName: companyName,
          currency: currency,
          demoData: demoData,
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));
        continue; // Loop to handle any dialogs that follow
      }

      // Check for paymentForm
      if (await CommonTest.doesExistKey(tester, 'paymentForm')) {
        debugPrint('AuthTest: PaymentForm detected, clicking pay...');
        await CommonTest.tapByKey(tester, 'pay');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        continue;
      }

      // Check for TrialWelcomeHelper dialog (shown after TenantSetupDialog)
      if (await CommonTest.doesExistKey(tester, 'getStarted')) {
        debugPrint(
          'AuthTest: TrialWelcomeHelper dialog detected, clicking getStarted...',
        );
        await CommonTest.tapByKey(tester, 'getStarted');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        continue;
      }

      // Check if we're authenticated
      if (await isAuthenticated(tester)) {
        debugPrint('AuthTest: Authentication complete, dashboard reached!');
        return true;
      }

      // If login form is still visible, break - something may be wrong
      if (await isLoginFormDisplayed(tester)) {
        debugPrint('AuthTest: Still on login form after attempt $attempts');
        // Don't continue looping if we're back to login
        if (attempts >= 3) {
          break;
        }
      }
    }

    debugPrint('AuthTest: Max attempts reached without reaching dashboard');
    return await isAuthenticated(tester);
  }

  /// Handle the trial welcome dialog if displayed.
  ///
  /// This handles both:
  /// - New TrialWelcomeDialog (key: 'startTrial') - shown when apiKey='trialWelcome'
  /// - TrialWelcomeHelper dialog (key: 'getStarted') - shown after TenantSetupDialog
  ///
  /// Returns true if the dialog was handled, false if not displayed.
  static Future<bool> handleTrialWelcome(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Check for TrialWelcomeDialog (startTrial button)
    if (await CommonTest.doesExistKey(tester, 'startTrial')) {
      debugPrint('TrialWelcomeDialog detected, tapping startTrial');
      await CommonTest.tapByKey(tester, 'startTrial');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // After startTrial, TenantSetupDialog is shown
      // The caller should handle TenantSetupDialog separately
      return true;
    }

    // Check for TrialWelcomeHelper dialog (getStarted button)
    if (await CommonTest.doesExistKey(tester, 'getStarted')) {
      debugPrint('TrialWelcomeHelper dialog detected, tapping getStarted');
      await CommonTest.tapByKey(tester, 'getStarted');
      await tester.pumpAndSettle();
      return true;
    }

    return false;
  }

  /// Check if TrialWelcome dialog (new flow) is displayed.
  static Future<bool> isTrialWelcomeDialogDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'startTrial');
  }

  /// Check if login form is displayed.
  static Future<bool> isLoginFormDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'username') &&
        await CommonTest.doesExistKey(tester, 'password');
  }

  /// Check if tenant setup dialog is displayed.
  static Future<bool> isTenantSetupDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // TenantSetupDialog has companyName but not in the context of login form
    bool hasCompanyName = await CommonTest.doesExistKey(tester, 'companyName');
    bool hasSubmit = await CommonTest.doesExistKey(tester, 'submit');
    return hasCompanyName && hasSubmit;
  }

  /// Check if password change form is displayed.
  static Future<bool> isPasswordChangeDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'password') &&
        await CommonTest.doesExistKey(tester, 'password2');
  }

  /// Check if trial welcome dialog is displayed.
  /// Checks for both TrialWelcomeDialog (startTrial) and TrialWelcomeHelper (getStarted).
  static Future<bool> isTrialWelcomeDisplayed(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'getStarted') ||
        await CommonTest.doesExistKey(tester, 'startTrial');
  }

  /// Check if user is authenticated (dashboard visible).
  static Future<bool> isAuthenticated(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return await CommonTest.doesExistKey(tester, 'HomeFormAuth');
  }

  /// Wait for authentication to complete and reach dashboard.
  static Future<void> waitForDashboard(
    WidgetTester tester, {
    int maxSeconds = 10,
  }) async {
    int attempts = 0;
    while (attempts < maxSeconds * 2) {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      if (await isAuthenticated(tester)) {
        return;
      }
      attempts++;
    }
    // Final check with assertion
    expect(
      find.byKey(const Key('HomeFormAuth')),
      findsOneWidget,
      reason: 'Dashboard not reached after $maxSeconds seconds',
    );
  }

  /// Complete the password change form.
  static Future<void> changePassword(
    WidgetTester tester, {
    required String newPassword,
    required String confirmPassword,
  }) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));

    if (await isPasswordChangeDisplayed(tester)) {
      await CommonTest.enterText(tester, 'password', newPassword);
      await CommonTest.enterText(tester, 'password2', confirmPassword);

      // Find and tap the submit button
      // The button text varies, try common options
      final submitFinder = find.text('Submit New Password');
      if (tester.any(submitFinder)) {
        await tester.tap(submitFinder);
      }
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  /// Request password reset.
  static Future<void> requestPasswordReset(
    WidgetTester tester, {
    required String email,
  }) async {
    // Tap forgot password link
    final forgotPasswordFinder = find.text('Forgot Password?');
    if (tester.any(forgotPasswordFinder)) {
      await tester.tap(forgotPasswordFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter email in reset dialog
      await CommonTest.enterText(tester, 'username', email);

      // Submit the reset request
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  /// Verify error message is displayed.
  static Future<bool> hasErrorMessage(
    WidgetTester tester,
    String errorText,
  ) async {
    await tester.pumpAndSettle();
    return tester.any(find.textContaining(errorText));
  }

  /// Verify success message is displayed.
  static Future<bool> hasSuccessMessage(
    WidgetTester tester,
    String successText,
  ) async {
    await tester.pumpAndSettle();
    return tester.any(find.textContaining(successText));
  }

  // ===============================low level tests ============================

  static Future<void> gotoMainMenu(WidgetTester tester) async {
    await CommonTest.selectMainMenu(tester, "tap/");
  }

  static Future<void> clearDemoData(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'demoData', seconds: CommonTest.waitTime);
  }

  static Future<void> enterCompanyName(WidgetTester tester, String name) async {
    await CommonTest.enterText(tester, 'companyName', name);
  }

  static Future<void> enterCurrency(
    WidgetTester tester,
    Currency currency,
  ) async {
    await CommonTest.selectDropDown(tester, 'currency', currency.description!);
  }

  static Future<void> enterEmailAddress(
    WidgetTester tester,
    String emailAddress,
  ) async {
    await CommonTest.enterText(tester, 'email', emailAddress);
  }

  static Future<void> enterFirstName(
    WidgetTester tester,
    String firstName,
  ) async {
    await CommonTest.enterText(tester, 'firstName', firstName);
  }

  static Future<void> enterLastname(
    WidgetTester tester,
    String lastName,
  ) async {
    await CommonTest.enterText(tester, 'lastName', lastName);
  }

  static Future<void> enterLoginName(
    WidgetTester tester,
    String loginName,
  ) async {
    await CommonTest.enterText(tester, 'username', loginName);
  }

  static Future<void> enterPassword(
    WidgetTester tester,
    String password,
  ) async {
    await CommonTest.enterText(tester, 'password', password);
  }

  static Future<void> pressLoginWithExistingId(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'loginButton', seconds: 1);
  }

  static Future<void> pressLogin(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'login', seconds: CommonTest.waitTime);
  }

  static Future<void> pressNewCompany(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'newCompButton');
  }

  /// Toggle password visibility in login/password forms.
  static Future<void> togglePasswordVisibility(WidgetTester tester) async {
    final visibilityIcon = find.byIcon(Icons.visibility);
    final visibilityOffIcon = find.byIcon(Icons.visibility_off);

    if (tester.any(visibilityIcon)) {
      await tester.tap(visibilityIcon.first);
    } else if (tester.any(visibilityOffIcon)) {
      await tester.tap(visibilityOffIcon.first);
    }
    await tester.pumpAndSettle();
  }

  /// Verify the form validation message is displayed.
  static Future<bool> hasValidationError(
    WidgetTester tester,
    String fieldKey,
  ) async {
    await tester.pumpAndSettle();
    // Check for error decoration on the field
    final field = find.byKey(Key(fieldKey));
    if (tester.any(field)) {
      // Look for error text widgets near the field
      // This is a simplified check - actual implementation may vary
      return tester.any(find.textContaining('required')) ||
          tester.any(find.textContaining('error')) ||
          tester.any(find.textContaining('invalid'));
    }
    return false;
  }
}
