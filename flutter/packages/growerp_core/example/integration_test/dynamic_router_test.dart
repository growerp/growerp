// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc;
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:core_example/main.dart';

/// Integration test for dynamic router functionality.
///
/// Uses CoreApp directly so the menu configuration is loaded from the backend
/// (CORE_EXAMPLE_DEFAULT), matching the real-app behaviour of admin/freelance/etc.
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
    await PersistFunctions.persistTest(SaveTest());
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> startCoreApp(WidgetTester tester, RestClient restClient) async {
    Bloc.observer = AppBlocObserver();
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
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoadingIndicator).evaluate().isEmpty) break;
    }
  }

  testWidgets('Dynamic Router - Auth Redirect Test', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    await startCoreApp(tester, restClient);

    // Before login, we should see the home form (login screen)
    // The dynamic router should redirect unauthenticated users to '/'
    expect(find.byType(HomeForm), findsOneWidget);
    debugPrint('✓ Unauthenticated user redirected to HomeForm');
  });

  testWidgets('Dynamic Router - Route Generation and Navigation', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    await startCoreApp(tester, restClient);

    // Login — creates company and admin, seeding CORE_EXAMPLE_DEFAULT menu items
    await CommonTest.createCompanyAndAdmin(tester);

    // After login CoreApp rebuilds: AppSplashScreen fires MenuConfigLoad, then
    // CoreApp swaps to the full dynamic router. Wait for a dashboard card to
    // appear (up to 20 s) instead of pumpAndSettle which hangs on WsClient timers.
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('tap/companies')).evaluate().isNotEmpty) break;
    }

    // Verify dashboard cards exist for backend-seeded CORE_EXAMPLE_DEFAULT items.
    // DashboardCard uses keys in the format Key('tap<route>'), e.g. Key('tap/companies').
    // findsWidgets is used because the navigation rail and the dashboard card
    // both carry the same key on tablet/desktop layouts.
    expect(find.byKey(const Key('tap/companies')), findsWidgets);
    expect(find.byKey(const Key('tap/crm')), findsWidgets);
    debugPrint(
      '✓ Dynamic menu routes generated from CORE_EXAMPLE_DEFAULT backend config',
    );

    // Verify logout/auth button is present on main route
    expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);
    debugPrint('✓ Auth button visible on main route');

    // Navigate to Organization route via dashboard card
    await tester.tap(find.byKey(const Key('tap/companies')));
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('HomeFormAuth')).evaluate().isEmpty) break;
    }

    // On sub-route, the main dashboard (HomeFormAuth) should NOT be visible
    expect(find.byKey(const Key('HomeFormAuth')), findsNothing);
    debugPrint('✓ Dashboard not visible on sub-route');

    debugPrint('✓ Dynamic router test completed successfully');
  });
}
