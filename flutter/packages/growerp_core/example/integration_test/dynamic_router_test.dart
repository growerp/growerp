// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Integration test for dynamic router functionality.
///
/// Uses CommonTest.startTestApp so the GrowERP initial-tenant detection
/// (company name pre-filled with 'GrowERP') is exercised on fresh backends.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Dynamic Router - Auth Redirect Test', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    final router = createDynamicCoreRouter(
      [coreMenuConfig],
      rootNavigatorKey: GlobalKey<NavigatorState>(),
    );
    final menuConfigBloc = MenuConfigBloc(restClient, 'core_example')
      ..add(MenuConfigUpdateLocal(coreMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: 'Dynamic Router Test',
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
      ],
    );

    // Before login, we should see the home form (login screen)
    expect(find.byType(HomeForm), findsOneWidget);
    debugPrint('✓ Unauthenticated user redirected to HomeForm');
  });

  testWidgets('Dynamic Router - Route Generation and Navigation', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    final router = createDynamicCoreRouter(
      [coreMenuConfig],
      rootNavigatorKey: GlobalKey<NavigatorState>(),
    );
    final menuConfigBloc = MenuConfigBloc(restClient, 'core_example')
      ..add(MenuConfigUpdateLocal(coreMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: 'Dynamic Router Test',
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
      ],
    );

    // Creates company and admin — exercises the GrowERP tenant detection if
    // the backend is fresh (company name pre-filled with 'GrowERP').
    await CommonTest.createCompanyAndAdmin(tester);

    // After login, TopApp's BlocListener fires MenuConfigLoad which replaces
    // the locally-seeded coreMenuConfig with the backend's seed data. The
    // backend's CORE_EXAMPLE_DEFAULT config uses different routes (/companies,
    // /crm, …) than the static coreMenuConfig (/company, /user). Re-seed the
    // bloc so CoreDashboard renders the dashboard cards with the expected keys.
    menuConfigBloc.add(MenuConfigUpdateLocal(coreMenuConfig));

    // Wait for CoreDashboard to rebuild with the re-seeded configuration.
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byKey(const Key('tap/company')))) break;
    }

    // Verify dashboard cards exist for the static menu configuration.
    expect(find.byKey(const Key('tap/company')), findsWidgets);
    expect(find.byKey(const Key('tap/user')), findsWidgets);
    debugPrint('✓ Dynamic menu routes generated from static config');

    // Verify auth button is present on main route
    expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);
    debugPrint('✓ Auth button visible on main route');

    // Navigate to Organization route via dashboard card
    await tester.tap(find.byKey(const Key('tap/company')));
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
