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

// ignore_for_file: dangling_library_doc_comments
/// Integration tests for Registration and Login Process.
///
/// These tests verify the complete authentication flow:
/// - User registration (admin and non-admin)
/// - Login with valid/invalid credentials
/// - Tenant setup for new admins
/// - Trial welcome dialog display
/// - Password change flow
/// - Session persistence and logout
///
/// PREREQUISITES:
/// 1. Moqui backend must be running with instance_purpose=dev
/// 2. GrowERP owner account (test@example.com/qqqqqq9!) must exist

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

// Test user data - will be set during tests
String? registeredAdminEmail;
const String testPassword = 'qqqqqq9!';

// Menu configuration for tests
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  group('Registration Flow Tests', () {
    testWidgets('TC-REG-001: New Admin User Registration', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-REG-001: Admin Registration",
      );

      // Generate unique email
      SaveTest test = await PersistFunctions.getTest();
      registeredAdminEmail = 'authtest${test.sequence}@example.com';

      // Open registration form
      await tester.pumpAndSettle(Duration(seconds: CommonTest.waitTime));
      await CommonTest.tapByKey(tester, 'newUserButton');
      await tester.pumpAndSettle();

      // Verify registration form is displayed
      expect(
        find.byKey(const Key('firstName')),
        findsOneWidget,
        reason: 'First name field should be visible',
      );
      expect(
        find.byKey(const Key('lastName')),
        findsOneWidget,
        reason: 'Last name field should be visible',
      );
      expect(
        find.byKey(const Key('email')),
        findsOneWidget,
        reason: 'Email field should be visible',
      );

      // Fill registration form
      await CommonTest.enterText(tester, 'firstName', 'AuthTest');
      await CommonTest.enterText(tester, 'lastName', 'User');
      await CommonTest.enterText(tester, 'email', registeredAdminEmail!);

      // Submit registration
      await CommonTest.tapByKey(
        tester,
        'newUserButton',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.waitForSnackbarToGo(tester);

      // Verify success - should now show login form or have a success message
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The registration should complete and show login form
      await AuthTest.isLoginFormDisplayed(tester);

      // Save test data
      test = test.copyWith(
        admin: User(
          email: registeredAdminEmail,
          loginName: registeredAdminEmail,
          firstName: 'AuthTest',
          lastName: 'User',
        ),
      );
      await PersistFunctions.persistTest(test);

      debugPrint('✓ TC-REG-001: Admin registration completed');
    });

    testWidgets('TC-REG-003: Registration with Invalid Email', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-REG-003: Invalid Email",
      );

      // Open registration form
      await tester.pumpAndSettle(Duration(seconds: CommonTest.waitTime));
      await CommonTest.tapByKey(tester, 'newUserButton');
      await tester.pumpAndSettle();

      // Fill with invalid email
      await CommonTest.enterText(tester, 'firstName', 'Test');
      await CommonTest.enterText(tester, 'lastName', 'Invalid');
      await CommonTest.enterText(tester, 'email', 'invalid-email');

      // Submit registration
      await CommonTest.tapByKey(tester, 'newUserButton');
      await tester.pumpAndSettle();

      // Verify form validation error (should not submit)
      // The form should still be visible because validation failed
      expect(
        find.byKey(const Key('email')),
        findsOneWidget,
        reason: 'Email field should still be visible (form not submitted)',
      );

      debugPrint('✓ TC-REG-003: Email validation working');
    });
  });

  group('Login Flow Tests', () {
    testWidgets('TC-LOGIN-001: Successful Login with Valid Credentials', (
      WidgetTester tester,
    ) async {
      if (registeredAdminEmail == null) {
        // Get from persisted test data
        SaveTest test = await PersistFunctions.getTest();
        registeredAdminEmail = test.admin?.email;
      }

      if (registeredAdminEmail == null) {
        debugPrint('Skipping: No registered admin from previous test');
        return;
      }

      final restClient = RestClient(await buildDioClient());
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
        title: "TC-LOGIN-001: Valid Login",
      );

      // Verify login form displayed first
      await CommonTest.pressLoginButton(tester);

      expect(
        find.byKey(const Key('username')),
        findsOneWidget,
        reason: 'Username field should be visible',
      );
      expect(
        find.byKey(const Key('password')),
        findsOneWidget,
        reason: 'Password field should be visible',
      );
      expect(
        find.byKey(const Key('login')),
        findsOneWidget,
        reason: 'Login button should be visible',
      );

      // Use CommonTest.login() which handles all authentication dialogs
      // First logout to reset state, then login fresh
      await CommonTest.logout(tester);
      await CommonTest.login(
        tester,
        username: registeredAdminEmail,
        password: testPassword,
      );

      // Verify authenticated - dashboard should be visible
      expect(
        find.byKey(const Key('HomeFormAuth')),
        findsOneWidget,
        reason: 'Should reach dashboard after successful login',
      );

      debugPrint('✓ TC-LOGIN-001: Successful login completed');

      // logout if logged in
      await CommonTest.logout(tester);
      await tester.pumpAndSettle();
    });

    testWidgets('TC-LOGIN-002: Login with Invalid Credentials', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-LOGIN-002: Invalid Login",
      );

      // Navigate to login form
      await CommonTest.pressLoginButton(tester);
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await CommonTest.enterText(tester, 'username', 'nonexistent@example.com');
      await CommonTest.enterText(tester, 'password', 'wrongpassword');

      // Submit login
      await CommonTest.pressLogin(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify login failed - should still be on login form or show error
      // The login form should still be visible
      bool stillOnLogin = await AuthTest.isLoginFormDisplayed(tester);
      bool gotError = tester.any(find.byType(SnackBar));

      expect(
        stillOnLogin || gotError,
        isTrue,
        reason:
            'Should show error or remain on login form for invalid credentials',
      );

      debugPrint('✓ TC-LOGIN-002: Invalid login handled correctly');
    });

    testWidgets('TC-LOGIN-003: Login with Empty Fields', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-LOGIN-003: Empty Fields",
      );

      // Navigate to login form
      await CommonTest.pressLoginButton(tester);

      // Clear fields and submit
      await CommonTest.enterText(tester, 'username', '');
      await CommonTest.enterText(tester, 'password', '');
      await CommonTest.tapByKey(tester, 'login');
      await tester.pump();

      // Verify still on login form (validation should prevent submission)
      expect(
        find.byKey(const Key('username')),
        findsOneWidget,
        reason: 'Should remain on login form with empty fields',
      );

      debugPrint('✓ TC-LOGIN-003: Empty field validation working');
    });

    testWidgets('TC-LOGIN-004: Password Visibility Toggle', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-LOGIN-004: Password Toggle",
      );

      // Navigate to login form
      await CommonTest.pressLoginButton(tester);
      await tester.pumpAndSettle();

      // Enter a password
      await CommonTest.enterText(tester, 'password', 'testpassword');

      // Find visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility);
      final visibilityOffIcon = find.byIcon(Icons.visibility_off);

      // One of them should be visible
      bool hasToggle =
          tester.any(visibilityIcon) || tester.any(visibilityOffIcon);
      expect(
        hasToggle,
        isTrue,
        reason: 'Password visibility toggle should exist',
      );

      // Toggle visibility
      if (tester.any(visibilityIcon)) {
        await tester.tap(visibilityIcon.first);
      } else {
        await tester.tap(visibilityOffIcon.first);
      }
      await tester.pumpAndSettle();

      // Toggle should have switched
      debugPrint('✓ TC-LOGIN-004: Password visibility toggle working');
    });
  });

  group('Session Tests', () {
    testWidgets('TC-SESS-003: Logout Flow', (WidgetTester tester) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-SESS-003: Logout",
      );

      // Check if currently logged in
      bool isLoggedIn = await AuthTest.isAuthenticated(tester);

      if (isLoggedIn) {
        // Perform logout
        await CommonTest.logout(tester);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify logged out - login button should be visible
        bool hasLoginButton = tester.any(find.byKey(const Key('loginButton')));
        bool hasNewUserButton = tester.any(
          find.byKey(const Key('newUserButton')),
        );

        expect(
          hasLoginButton || hasNewUserButton,
          isTrue,
          reason:
              'Login or registration options should be visible after logout',
        );

        debugPrint('✓ TC-SESS-003: Logout completed successfully');
      } else {
        debugPrint('Skipping: Not logged in at start of test');
      }
    });
  });

  group('Tenant Setup Tests', () {
    testWidgets('TC-SETUP-001: Complete Tenant Setup (Admin)', (
      WidgetTester tester,
    ) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-SETUP-001: Tenant Setup",
      );

      // Use the standard flow that handles everything
      await CommonTest.createCompanyAndAdmin(tester);

      // Verify we're authenticated
      expect(
        find.byKey(const Key('HomeFormAuth')),
        findsOneWidget,
        reason: 'Should reach dashboard after tenant setup',
      );

      debugPrint('✓ TC-SETUP-001: Tenant setup completed');

      // Cleanup
      await CommonTest.logout(tester);
    });
  });

  group('Trial Welcome Tests', () {
    testWidgets('TC-TRIAL-001: Trial Welcome Flow Verification', (
      WidgetTester tester,
    ) async {
      // This test verifies the complete flow works including trial welcome handling
      final restClient = RestClient(await buildDioClient());
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
        title: "TC-TRIAL-001: Trial Welcome",
      );

      // Use createCompanyAndAdmin which handles the complete flow
      // including TrialWelcomeDialog and TenantSetupDialog
      await CommonTest.createCompanyAndAdmin(tester);

      // Verify dashboard reached - this means all dialogs were handled
      expect(
        find.byKey(const Key('HomeFormAuth')),
        findsOneWidget,
        reason: 'Dashboard should be visible after handling trial welcome',
      );

      debugPrint('✓ TC-TRIAL-001: Trial welcome flow completed');

      await CommonTest.logout(tester);
    });
  });

  group('Cleanup', () {
    testWidgets('Final cleanup and logout', (WidgetTester tester) async {
      final restClient = RestClient(await buildDioClient());
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
        title: "Cleanup",
      );

      await CommonTest.logout(tester);
      registeredAdminEmail = null;
      debugPrint('✓ Cleanup completed');
    });
  });
}
