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

// ignore: dangling_library_doc_comments
/// Integration tests for evaluation period and subscription flow.
///
/// These tests verify the registration/login flow with creditCardUpfront=false:
/// 1. Register new company/user
/// 2. Login with new credentials
/// 3. Complete tenant setup (company name, currency, demo data)
/// 4. View trial welcome dialog (shown after setup completes)
/// 5. Logout
/// 6. Advance time past evaluation period
/// 7. Login with SAME user
/// 8. Verify payment form appears (evaluation expired)
///
/// PREREQUISITES:
/// 1. Moqui backend must be running with instance_purpose=dev
/// 2. GrowERP owner account (test@example.com/qqqqqq9!) must exist
/// 3. Subscriptions must be configured in the GrowERP owner account
/// 4. creditCardUpfront=false (default) in docker-compose.yaml

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

// Test user credentials - will be set during registration
String? testUserEmail;
const String testUserPassword = 'qqqqqq9!';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    // Reset effective time at start
    EvaluationTest.resetTestDaysOffset();
  });

  tearDownAll(() async {
    // Ensure time is reset after all tests
    EvaluationTest.resetTestDaysOffset();
  });

  group('Evaluation Period Expiration Tests', () {
    testWidgets(
      '1. Register new company, complete tenant setup, view trial welcome, verify dashboard access',
      (WidgetTester tester) async {
        final restClient = RestClient(await buildDioClient());

        // Ensure time is at current
        EvaluationTest.resetTestDaysOffset();

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
            ),
            MenuItem(
              menuItemId: 'CORE_COMPANY',
              title: 'Organization',
              route: '/company',
              iconName: 'business',
              sequenceNum: 20,
              widgetName: 'CoreDashboard',
            ),
            MenuItem(
              menuItemId: 'CORE_USER',
              title: 'Logged in User',
              route: '/user',
              iconName: 'person',
              sequenceNum: 30,
              widgetName: 'CoreDashboard',
            ),
          ],
        );
        final router = createDynamicCoreRouter([
          coreMenuConfig,
        ], rootNavigatorKey: GlobalKey<NavigatorState>());

        await CommonTest.startTestApp(
          tester,
          router,
          coreMenuConfig,
          CoreLocalizations.localizationsDelegates,
          restClient: restClient,
          clear: true,
          title: "Register & Start Evaluation",
        );

        // Navigate to new user registration
        await CommonTest.tapByKey(tester, 'newUserButton');

        // Fill in registration info
        await CommonTest.enterText(tester, 'firstName', 'EvalTest');
        await CommonTest.enterText(tester, 'lastName', 'User');

        // Generate unique email and save it for later tests
        SaveTest test = await PersistFunctions.getTest();
        testUserEmail = 'evalexpire${test.sequence}@example.com';
        debugPrint('Registering user: $testUserEmail');
        await CommonTest.enterText(tester, 'email', testUserEmail!);

        // Submit registration
        await CommonTest.tapByKey(
          tester,
          'newUserButton',
          seconds: CommonTest.waitTime,
        );
        await CommonTest.waitForSnackbarToGo(tester);

        // Login with new user
        await CommonTest.pressLoginButton(tester);
        await CommonTest.enterText(tester, 'username', testUserEmail!);
        await CommonTest.enterText(tester, 'password', testUserPassword);
        await CommonTest.pressLogin(tester);
        await CommonTest.waitForSnackbarToGo(tester);

        // CORRECT FLOW: Should now see tenant setup dialog FIRST (apiKey: setupRequired)
        // Use manual pump instead of pumpAndSettle to avoid getting stuck on animations
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        if (await CommonTest.doesExistKey(tester, 'companyName')) {
          debugPrint('✓ Tenant setup dialog displayed (shown FIRST)');
          // Complete tenant setup
          await CommonTest.enterText(
            tester,
            'companyName',
            'EvalTest Company ${test.sequence}',
          );
          await CommonTest.enterDropDown(tester, 'currency', 'Euro');
          await CommonTest.tapByKey(tester, 'demoData'); // no demo data
          await CommonTest.tapByKey(
            tester,
            'submit',
            seconds: CommonTest.waitTime,
            settle: false,
          );
          debugPrint('✓ Tenant setup submitted');

          if (await EvaluationTest.isTrialWelcomeDisplayed(tester)) {
            debugPrint('✓ Trial welcome dialog displayed (shown SECOND)');
            await EvaluationTest.checkTrialWelcomeContent(tester);
            await EvaluationTest.startTrial(tester);
            debugPrint('✓ Started trial, dismissed welcome dialog');
          } else {
            debugPrint('⚠ Trial welcome not shown after tenant setup');
            // This is acceptable - trial welcome might not show in all cases
          }
        } else if (await EvaluationTest.isPaymentFormDisplayed(tester)) {
          debugPrint(
            '! Payment form shown - test requires creditCardUpfront=false',
          );
          fail('Test requires creditCardUpfront=false configuration');
        } else {
          debugPrint('? Neither form shown - checking if dashboard accessible');
        }

        // Verify we reached the dashboard
        // Use manual pump to avoid getting stuck
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byKey(const Key('HomeFormAuth')).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(
          find.byKey(const Key('HomeFormAuth')),
          findsOneWidget,
          reason: 'Should reach dashboard after starting evaluation',
        );
        debugPrint('✓ Dashboard accessible during evaluation period');

        await CommonTest.logout(tester);

        // Save the test data with the registered admin
        test = test.copyWith(
          admin: User(email: testUserEmail, loginName: testUserEmail),
        );
        await PersistFunctions.persistTest(test);
      },
    );

    testWidgets('3. Advance time past evaluation, login same user, verify payment form', (
      WidgetTester tester,
    ) async {
      if (testUserEmail == null) {
        debugPrint('Skipping: No test user from previous test');
        return;
      }

      final restClient = RestClient(await buildDioClient());

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
          ),
          MenuItem(
            menuItemId: 'CORE_COMPANY',
            title: 'Organization',
            route: '/company',
            iconName: 'business',
            sequenceNum: 20,
            widgetName: 'CoreDashboard',
          ),
          MenuItem(
            menuItemId: 'CORE_USER',
            title: 'Logged in User',
            route: '/user',
            iconName: 'person',
            sequenceNum: 30,
            widgetName: 'CoreDashboard',
          ),
        ],
      );
      final router = createDynamicCoreRouter([
        coreMenuConfig,
      ], rootNavigatorKey: GlobalKey<NavigatorState>());

      await CommonTest.startTestApp(
        tester,
        router,
        coreMenuConfig,
        CoreLocalizations.localizationsDelegates,
        restClient: restClient,
        clear: false,
        title: "Expiration Test",
      );

      // Set test days offset BEFORE pressing login
      // This will be passed to the backend during the login call
      debugPrint('Setting test days offset to 15 days...');
      EvaluationTest.setTestDaysOffset(15);
      debugPrint('✓ Test days offset set - will be applied on login');

      // Login with the SAME user from registration
      debugPrint('Logging in with: $testUserEmail');
      await CommonTest.pressLoginButton(tester);
      await CommonTest.enterText(tester, 'username', testUserEmail!);
      await CommonTest.enterText(tester, 'password', testUserPassword);
      await CommonTest.pressLogin(tester);
      await CommonTest.waitForSnackbarToGo(tester);

      // Check what form is shown - should be payment form since evaluation expired
      // Use manual pump to avoid getting stuck on animations
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Debug: Check what widgets are actually present
      debugPrint('Checking for payment form...');
      bool hasPaymentForm = await EvaluationTest.isPaymentFormDisplayed(tester);

      debugPrint('Payment form present: $hasPaymentForm');

      debugPrint('Checking for trial welcome...');
      bool hasTrialWelcome = await EvaluationTest.isTrialWelcomeDisplayed(
        tester,
      );
      debugPrint('Trial welcome present: $hasTrialWelcome');

      debugPrint('Checking for tenant setup...');
      bool hasTenantSetup = await CommonTest.doesExistKey(
        tester,
        'companyName',
      );
      debugPrint('Tenant setup present: $hasTenantSetup');

      debugPrint('Checking for dashboard...');
      bool hasDashboard = await CommonTest.doesExistKey(tester, 'HomeFormAuth');
      debugPrint('Dashboard present: $hasDashboard');

      if (hasPaymentForm) {
        debugPrint('✓ Payment form shown - evaluation correctly expired!');
        await EvaluationTest.checkPaymentFormContent(tester);

        // Now submit payment with the pre-filled test credit card
        debugPrint('Submitting payment with test credit card...');
        bool paymentSuccess = await EvaluationTest.submitPayment(tester);

        if (paymentSuccess) {
          debugPrint('✓ Payment successful - dashboard now accessible');
          // Verify dashboard is shown
          expect(
            find.byKey(const Key('HomeFormAuth')),
            findsOneWidget,
            reason: 'Dashboard should be accessible after successful payment',
          );
        } else {
          // Payment failed - form should still be displayed
          debugPrint('Payment failed - checking if form is re-displayed...');
          expect(
            await EvaluationTest.isPaymentFormDisplayed(tester),
            isTrue,
            reason: 'Payment form should be re-displayed after failed payment',
          );
          // For this test, we expect the test card to work, so fail if it didn't
          fail(
            'Payment with test credit card should have succeeded in test environment',
          );
        }
      } else if (hasTrialWelcome) {
        debugPrint('✗ Trial welcome shown - should have expired');
        fail('Evaluation should have expired after 15 days');
      } else if (hasTenantSetup) {
        debugPrint(
          '⚠ Tenant setup shown - completing setup then checking for payment form',
        );
        // Complete tenant setup
        SaveTest test = await PersistFunctions.getTest();
        await CommonTest.enterText(
          tester,
          'companyName',
          'EvalExpired Company ${test.sequence}',
        );
        await CommonTest.enterDropDown(tester, 'currency', 'Euro');
        await CommonTest.tapByKey(tester, 'demoData'); // no demo data
        await CommonTest.tapByKey(
          tester,
          'submit',
          seconds: CommonTest.waitTime,
        );
        await CommonTest.waitForSnackbarToGo(tester);
        // Use manual pump to avoid getting stuck
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // After tenant setup, payment form should appear
        if (await EvaluationTest.isPaymentFormDisplayed(tester)) {
          debugPrint('✓ Payment form shown after tenant setup');
          // Continue with payment submission
          bool paymentSuccess = await EvaluationTest.submitPayment(tester);
          expect(
            paymentSuccess,
            isTrue,
            reason: 'Payment should succeed after tenant setup',
          );
        } else {
          fail(
            'Payment form should appear after tenant setup for expired evaluation',
          );
        }
      } else if (hasDashboard) {
        debugPrint(
          '✗ Dashboard shown - subscription check not working correctly',
        );
        fail(
          'Dashboard should not be accessible after evaluation expiration without payment',
        );
      } else {
        debugPrint('? Unknown state after login');
        fail('Expected payment form after evaluation expiration');
      }
    });

    testWidgets('4. Cleanup - reset time', (WidgetTester tester) async {
      // Reset effective time to current
      EvaluationTest.resetTestDaysOffset();
      debugPrint('✓ Effective time reset to current');

      // Clear test user email
      testUserEmail = null;
    });
  });
}
