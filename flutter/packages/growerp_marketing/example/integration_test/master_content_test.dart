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

import 'package:growerp_marketing_example/router_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_marketing/src/test_data.dart' as marketing_data;
import 'package:growerp_marketing/src/master_content/integration_test/master_content_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP master content test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createMarketingExampleRouter(),
      marketingMenuConfig,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("applicationId"),
      ),
      title: 'GrowERP master content test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await MasterContentTest.selectMasterContent(tester);
    await MasterContentTest.addMasterContent(
      tester,
      marketing_data.masterContents.sublist(0, 3),
    );
    await MasterContentTest.checkMasterContent(tester);
    await MasterContentTest.approveMasterContent(tester);
    await MasterContentTest.updateMasterContent(
      tester,
      marketing_data.updatedMasterContents.sublist(0, 3),
    );
    await MasterContentTest.checkMasterContent(tester);
    await MasterContentTest.deleteMasterContent(tester);
    await CommonTest.logout(tester);
  }, skip: false);
}
