/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
