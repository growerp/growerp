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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK knowledge-base test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK knowledge test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // Smoke only: adding/editing a knowledge doc chunks + embeds it server-side,
    // which requires a per-company Gemini API key (the same LLM dependency the
    // chat/approval surfaces have). On a keyless CI backend the create 400s, so
    // here we just verify the screen and its controls render. The full
    // add/check/update/delete steps live on AdkTest for key-equipped backends.
    await AdkTest.selectKnowledge(tester);
    await CommonTest.checkWidgetKey(tester, 'addKnowledge');
    await CommonTest.checkWidgetKey(tester, 'refreshKnowledge');

    await CommonTest.logout(tester);
  });
}
