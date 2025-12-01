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
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_marketing/src/test_data.dart' as assessment_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP assessment test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
      ),
      title: 'GrowERP assessment test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await AssessmentTest.selectAssessments(tester);
    await AssessmentTest.addAssessments(
      tester,
      assessment_data.assessments.sublist(0, 3),
    );
    await AssessmentTest.checkAssessments(tester);
    await AssessmentTest.updateAssessments(
      tester,
      assessment_data.updatedAssessments.sublist(0, 3),
    );
    await AssessmentTest.checkAssessments(tester);

    // Test questions for the first assessment

    SaveTest test = await PersistFunctions.getTest();
    String firstAssessmentId = test.assessments[0].pseudoId!;
    await QuestionTest.selectQuestions(tester, firstAssessmentId);
    await QuestionTest.addQuestions(
      tester,
      assessment_data.assessmentQuestions,
    );
    await QuestionTest.checkQuestions(tester);
    await QuestionTest.deleteLastQuestion(tester);

    // Go back to assessment list
    await CommonTest.tapByKey(tester, 'cancel'); // Close questions dialog
    await CommonTest.tapByKey(tester, 'cancel'); // Close assessment detail

    await AssessmentTest.deleteAssessments(tester);
    await CommonTest.logout(tester);
  });
}
