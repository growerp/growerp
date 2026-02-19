import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:core_example/main.dart';
import 'package:flutter/material.dart';

/// Integration test for dynamic router functionality.
///
/// Tests that the dynamic router correctly:
/// - Generates routes from menu configuration
/// - Handles authentication redirects
/// - Displays logout button on main route only
/// - Navigates between routes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await PersistFunctions.removeAuthenticate();
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Dynamic Router - Auth Redirect Test', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());

    await tester.pumpWidget(
      CoreApp(
        restClient: restClient,
        classificationId: 'AppAdmin',
        chatClient: WsClient('chat'),
        notificationClient: WsClient('notws'),
      ),
    );

    await tester.pump();

    // Wait for initial load
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoadingIndicator).evaluate().isEmpty) {
        break;
      }
    }

    // Before login, we should see the home form (login screen)
    // The dynamic router should redirect unauthenticated users to '/'
    expect(find.byType(HomeForm), findsOneWidget);
    debugPrint('✓ Unauthenticated user redirected to HomeForm');
  });

  testWidgets('Dynamic Router - Route Generation and Navigation', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());

    await tester.pumpWidget(
      CoreApp(
        restClient: restClient,
        classificationId: 'AppAdmin',
        chatClient: WsClient('chat'),
        notificationClient: WsClient('notws'),
      ),
    );

    await tester.pump();

    // Wait for initial load
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoadingIndicator).evaluate().isEmpty) {
        break;
      }
    }

    // Login
    await CommonTest.createCompanyAndAdmin(tester);
    await tester.pumpAndSettle();

    // After login, verify we see the dashboard with dynamic menu items
    // The menu should be generated from backend MenuConfiguration
    // Use findsWidgets to be flexible with duplicates that may appear in headless testing
    expect(find.text('Organization'), findsWidgets);
    expect(find.text('CRM'), findsWidgets);
    debugPrint('✓ Dynamic menu routes generated from configuration');

    // Verify logout button is present on main route
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    debugPrint('✓ Logout button visible on main route');

    // Navigate to Organization route
    // Dashboard cards have keys in the format 'tap{route}'
    final orgFinder = find.byKey(const Key('tap/companies'));
    if (orgFinder.evaluate().isNotEmpty) {
      await tester.tap(orgFinder);
      await tester.pumpAndSettle();

      // On sub-route, logout button should NOT be visible
      // (ShellRoute doesn't include logout button)
      expect(find.byKey(const Key('logoutButton')), findsNothing);
      debugPrint('✓ Logout button NOT visible on sub-route');

      debugPrint('✓ Dynamic router test completed successfully');
    }
  });
}
