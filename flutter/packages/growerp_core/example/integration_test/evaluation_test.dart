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
/// 2. Start evaluation period
/// 3. Logout
/// 4. Advance time past evaluation period
/// 5. Login with SAME user
/// 6. Verify payment form appears (evaluation expired)
///
/// PREREQUISITES:
/// 1. Moqui backend must be running with instance_purpose=dev
/// 2. GrowERP owner account (test@example.com/qqqqqq9!) must exist
/// 3. Subscriptions must be configured in the GrowERP owner account
/// 4. creditCardUpfront=false (default) in docker-compose.yaml

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/main.dart';
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/src/domains/authenticate/integration_test/evaluation_test.dart';

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
      '1. Register new company, start evaluation, verify dashboard access',
      (WidgetTester tester) async {
        final restClient = RestClient(await buildDioClient());

        // Ensure time is at current
        EvaluationTest.resetTestDaysOffset();

        const coreMenuConfig = MenuConfiguration(
          menuConfigurationId: 'CORE_EXAMPLE',
          appId: 'core_example',
          name: 'Core Example Menu',
          menuOptions: [
            MenuOption(
              menuOptionId: 'CORE_MAIN',
              title: 'Main',
              route: '/',
              iconName: 'dashboard',
              sequenceNum: 10,
              widgetName: 'CoreDashboard',
            ),
            MenuOption(
              menuOptionId: 'CORE_COMPANY',
              title: 'Organization',
              route: '/company',
              iconName: 'business',
              sequenceNum: 20,
              widgetName: 'CoreDashboard',
            ),
            MenuOption(
              menuOptionId: 'CORE_USER',
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
        await CommonTest.pressLoginWithExistingId(tester);
        await CommonTest.enterText(tester, 'username', testUserEmail!);
        await CommonTest.enterText(tester, 'password', testUserPassword);
        await CommonTest.pressLogin(tester);
        await CommonTest.waitForSnackbarToGo(tester);

        // Complete company info form (moreInfo)
        await tester.pumpAndSettle(const Duration(seconds: 1));
        if (await CommonTest.doesExistKey(tester, 'moreInfo')) {
          debugPrint('Filling in company info...');
          await CommonTest.enterText(
            tester,
            'companyName',
            'EvalTest Company ${test.sequence}',
          );
          await CommonTest.enterDropDown(tester, 'currency', 'Euro');
          await CommonTest.tapByKey(tester, 'demoData'); // no demo data
          await CommonTest.tapByKey(
            tester,
            'continue',
            seconds: CommonTest.waitTime,
          );
          await CommonTest.waitForSnackbarToGo(tester);
        }

        // Should now see evaluation welcome form (creditCardUpfront=false)
        await tester.pumpAndSettle(const Duration(seconds: 2));

        if (await EvaluationTest.isEvaluationWelcomeDisplayed(tester)) {
          debugPrint('✓ Evaluation welcome form displayed');
          await EvaluationTest.checkEvaluationWelcomeContent(tester);
          await EvaluationTest.startEvaluation(tester);
          debugPrint('✓ Started evaluation period');
        } else if (await EvaluationTest.isPaymentFormDisplayed(tester)) {
          debugPrint(
            '! Payment form shown - test requires creditCardUpfront=false',
          );
          fail('Test requires creditCardUpfront=false configuration');
        } else {
          debugPrint('? Neither form shown - checking if dashboard accessible');
        }

        // Verify we reached the dashboard
        await tester.pumpAndSettle(
          const Duration(seconds: CommonTest.waitTime),
        );
        expect(
          find.byKey(const Key('HomeFormAuth')),
          findsOneWidget,
          reason: 'Should reach dashboard after starting evaluation',
        );
        debugPrint('✓ Dashboard accessible during evaluation period');

        // Save the test data with the registered admin
        test = test.copyWith(
          admin: User(email: testUserEmail, loginName: testUserEmail),
        );
        await PersistFunctions.persistTest(test);
      },
    );

    testWidgets('2. Logout from evaluation account', (
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
        menuOptions: [
          MenuOption(
            menuOptionId: 'CORE_MAIN',
            title: 'Main',
            route: '/',
            iconName: 'dashboard',
            sequenceNum: 10,
            widgetName: 'CoreDashboard',
          ),
          MenuOption(
            menuOptionId: 'CORE_COMPANY',
            title: 'Organization',
            route: '/company',
            iconName: 'business',
            sequenceNum: 20,
            widgetName: 'CoreDashboard',
          ),
          MenuOption(
            menuOptionId: 'CORE_USER',
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
        title: "Logout",
      );

      // Should be logged in from previous test, logout
      await CommonTest.logout(tester);
      debugPrint('✓ Logged out successfully');
    });

    testWidgets(
      '3. Advance time past evaluation, login same user, verify payment form',
      (WidgetTester tester) async {
        if (testUserEmail == null) {
          debugPrint('Skipping: No test user from previous test');
          return;
        }

        final restClient = RestClient(await buildDioClient());

        const coreMenuConfig = MenuConfiguration(
          menuConfigurationId: 'CORE_EXAMPLE',
          appId: 'core_example',
          name: 'Core Example Menu',
          menuOptions: [
            MenuOption(
              menuOptionId: 'CORE_MAIN',
              title: 'Main',
              route: '/',
              iconName: 'dashboard',
              sequenceNum: 10,
              widgetName: 'CoreDashboard',
            ),
            MenuOption(
              menuOptionId: 'CORE_COMPANY',
              title: 'Organization',
              route: '/company',
              iconName: 'business',
              sequenceNum: 20,
              widgetName: 'CoreDashboard',
            ),
            MenuOption(
              menuOptionId: 'CORE_USER',
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
        await CommonTest.pressLoginWithExistingId(tester);
        await CommonTest.enterText(tester, 'username', testUserEmail!);
        await CommonTest.enterText(tester, 'password', testUserPassword);
        await CommonTest.pressLogin(tester);
        await CommonTest.waitForSnackbarToGo(tester);

        // Check what form is shown - should be payment form since evaluation expired
        await tester.pumpAndSettle(const Duration(seconds: 2));

        if (await EvaluationTest.isPaymentFormDisplayed(tester)) {
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
              reason:
                  'Payment form should be re-displayed after failed payment',
            );
            // For this test, we expect the test card to work, so fail if it didn't
            fail(
              'Payment with test credit card should have succeeded in test environment',
            );
          }
        } else if (await EvaluationTest.isEvaluationWelcomeDisplayed(tester)) {
          debugPrint('✗ Evaluation welcome shown - should have expired');
          fail('Evaluation should have expired after 15 days');
        } else if (await CommonTest.doesExistKey(tester, 'HomeFormAuth')) {
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
      },
    );

    testWidgets('4. Cleanup - reset time', (WidgetTester tester) async {
      // Reset effective time to current
      EvaluationTest.resetTestDaysOffset();
      debugPrint('✓ Effective time reset to current');

      // Clear test user email
      testUserEmail = null;
    });
  });
}
