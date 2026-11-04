// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos_example/router_builder.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    // registers as the admin app, the example itself is a shop
    GlobalConfiguration().updateValue('applicationId', 'AppAdmin');
  });

  testWidgets('a company of another app is told it has no till', (
    tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createPosExampleRouter(),
      posMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppAdmin'),
      applicationId: 'AppAdmin',
      title: "Point of sale other app test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('posNoAccess')), findsOneWidget);
  });
}
