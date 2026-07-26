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

// ignore_for_file: depend_on_referenced_packages
import 'package:growerp_activity_example/router_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_activity/src/integration_test/activity_test.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Activity test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createActivityExampleRouter(),
      activityMenuConfig,
      ActivityLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppAdmin'),
      title: "Activity test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await ActivityTest.selectActivities(tester);
    await ActivityTest.addActivities(tester, activities);
    await ActivityTest.updateActivities(tester);
    await ActivityTest.deleteLastActivity(tester);
    await CommonTest.logout(tester);
  });
}
