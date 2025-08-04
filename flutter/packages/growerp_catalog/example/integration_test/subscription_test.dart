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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:catalog_example/main.dart' as router;
import 'package:catalog_example/main.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  var title = 'GrowERP subscription test';

  testWidgets(title, (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      router.generateRoute,
      menuOptions,
      CatalogLocalizations.localizationsDelegates,
      title: title,
      restClient: restClient,
      blocProviders: getCatalogBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    );

    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "products": subscriptionProducts,
      "companies": customerCompanies
    });
    await SubscriptionTest.selectSubscriptions(tester);
    await SubscriptionTest.addSubscriptions(
        tester, subscriptions.sublist(0, 2));
    await SubscriptionTest.updateSubscriptions(
        tester, subscriptions.sublist(2, 4));
    await SubscriptionTest.deleteLastSubscription(tester);
  });
}
