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
import 'package:website_example/router_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/src/website/integration_test.dart/website_form_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP web form test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createWebsiteExampleRouter(),
      websiteMenuConfig,
      websiteExampleDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("applicationId"),
      ),
      title: 'GrowERP web form test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await WebsiteFormTest.selectWebForms(tester);

    List<WebsiteForm> webForms = await WebsiteFormTest.addWebForms(
      tester,
      newForms,
    );
    await WebsiteFormTest.checkWebForms(tester, webForms);

    // keep the allocated pseudoIds, change everything else
    List<WebsiteForm> updated = [
      for (int i = 0; i < webForms.length; i++)
        updatedForms[i].copyWith(pseudoId: webForms[i].pseudoId),
    ];
    await WebsiteFormTest.updateWebForms(tester, updated);
    await WebsiteFormTest.checkWebForms(tester, updated);

    await WebsiteFormTest.deleteLastWebForm(tester, updated.length);
    await CommonTest.logout(tester);
  });
}

List<WebsiteForm> newForms = [
  WebsiteForm(
    formName: 'Contact us',
    title: 'Get in touch',
    submitLabel: 'Send',
    successMessage: 'Thanks, we will be in touch shortly.',
    fields: [
      WebsiteFormField(label: 'Name', fieldType: 'text', isRequired: 'Y'),
      WebsiteFormField(label: 'Email', fieldType: 'email', isRequired: 'Y'),
    ],
  ),
  WebsiteForm(
    formName: 'Newsletter',
    title: 'Subscribe',
    submitLabel: 'Subscribe',
    successMessage: 'You are subscribed.',
    fields: [
      WebsiteFormField(label: 'Email', fieldType: 'email', isRequired: 'Y'),
    ],
  ),
];

List<WebsiteForm> updatedForms = [
  WebsiteForm(
    formName: 'Contact sales',
    title: 'Talk to sales',
    submitLabel: 'Request a call',
    successMessage: 'A sales rep will call you.',
    fields: [
      WebsiteFormField(label: 'Full name', fieldType: 'text', isRequired: 'Y'),
      WebsiteFormField(label: 'Work email', fieldType: 'email', isRequired: 'Y'),
      WebsiteFormField(label: 'Phone', fieldType: 'phone', isRequired: 'N'),
    ],
  ),
  WebsiteForm(
    formName: 'Product updates',
    title: 'Stay informed',
    submitLabel: 'Sign me up',
    successMessage: 'Signed up.',
    fields: [
      WebsiteFormField(label: 'Email address', fieldType: 'email', isRequired: 'Y'),
    ],
  ),
];
