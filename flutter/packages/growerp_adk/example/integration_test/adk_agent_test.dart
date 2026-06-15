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

import 'package:adk_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_adk/src/integration_test/adk_test.dart';

import 'adk_test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK agent test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK agent test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    await AdkTest.selectAgents(tester);
    // A read-only (safe-by-default) agent + a scoped/approval agent.
    await AdkTest.addAgents(tester, agents.sublist(0, 2));
    await AdkTest.checkAgents(tester);
    await AdkTest.updateAgents(tester, agentsUpdate.sublist(0, 2));
    await AdkTest.checkAgents(tester);
    await AdkTest.deleteAgents(tester);
    await CommonTest.logout(tester);
  });
}
