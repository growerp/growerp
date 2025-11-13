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

import 'package:assessment_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectAssessments(WidgetTester tester) async {
    await AssessmentTest.selectAssessments(tester);
  }

  testWidgets('''GrowERP assessment test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP Assessment Test',
      clear: true,
    );

    await CommonTest.createCompanyAndAdmin(tester);
    await selectAssessments(tester);

    // Test add assessments
    await AssessmentTest.addAssessments(tester, assessments.sublist(0, 3));

    // Test check assessments
    await AssessmentTest.checkAssessments(tester);

    // Test update assessments
    await AssessmentTest.updateAssessments(
      tester,
      updatedAssessments.sublist(0, 3),
    );

    // Test check updated assessments
    await AssessmentTest.checkAssessments(tester);

    // Test delete assessments
    await AssessmentTest.deleteAssessments(tester);

    await CommonTest.logout(tester);
  });
}
