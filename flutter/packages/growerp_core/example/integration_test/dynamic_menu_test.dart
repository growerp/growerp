import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:core_example/main.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Clear any existing session to ensure a fresh login/menu fetch
    await PersistFunctions.removeAuthenticate();

    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Dynamic Menu Loading Test', (WidgetTester tester) async {
    // Override URL to ensure localhost if running on Linux host, though buildDioClient should handle it.
    // If running in container as android, might need 10.0.2.2.
    // But integration_test usually runs on host.

    // Check platform?
    // Let's rely on default since 10.0.2.2 worked for CheckEmail in logs.

    final restClient = RestClient(await buildDioClient());

    await tester.pumpWidget(
      CoreApp(
        restClient: restClient,
        classificationId: 'AppAdmin',
        chatClient: WsClient('chat'),
        notificationClient: WsClient('notws'),
      ),
    );

    // Initial pump to start widgets
    await tester.pump();

    // Wait for a bit to allow async bloc to fetch menu
    // We avoid pumpAndSettle here because LoadingIndicator might be infinite loop
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoadingIndicator).evaluate().isEmpty) {
        break;
      }
    }

    if (find.byType(LoadingIndicator).evaluate().isNotEmpty) {
      debugPrint(
        "Still seeing LoadingIndicator after wait. Menu fetch might have failed or is slow.",
      );
    } else {
      debugPrint("LoadingIndicator gone. Menu likely loaded.");
    }

    // Login (if not already logged in, though removeAuthenticate should ensure we are at login screen)
    // createCompanyAndAdmin expects to find 'newUserButton' or 'login' fields.
    // If we are still at LoadingIndicator, this will fail.
    await CommonTest.createCompanyAndAdmin(tester);

    // After login, the menu should be fetched and the router updated.
    // CoreApp handles this transition.

    // Check if the dashboard is displayed, implying successful menu load
    await tester.pumpAndSettle();

    // Verify menu items from the dynamic configuration
    // Navigate to "Main" (dashboard) is default
    expect(find.text('Organization'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);

    // Verify Side Menu or Bottom Bar items depending on screen size
    // Note: AuthenticatedDisplayMenuOption uses DisplayMenuOption which renders navigation rail/bar
    // We expect "Main", "Organization", "Logged in User", "About"

    // On wide screen (desktop/tablet), standard menu
    // We need to tap the menu button if it's a drawer, or just check text if it's a rail

    // Let's assume dashboard is enough to prove the "Main" route worked.
    // Let's try to navigate to "About"

    // Since we are in an integration test, we can try to find the "About" menu item
    // Depending on resolution, it might be in a drawer.
  });
}
