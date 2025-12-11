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

import 'package:growerp_outreach_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/src/test_data.dart' as test_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP outreach campaign test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOutreachExampleRouter(),
      outreachMenuConfig,
      const [],
      restClient: restClient,
      blocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'GrowERP outreach campaign test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await OutreachCampaignTest.selectCampaigns(tester);
    await OutreachCampaignTest.addCampaigns(
      tester,
      test_data.campaigns.sublist(0, 3),
    );
    await OutreachCampaignTest.checkCampaigns(tester);
    await OutreachCampaignTest.updateCampaigns(
      tester,
      test_data.updatedCampaigns.sublist(0, 3),
    );
    await OutreachCampaignTest.checkCampaigns(tester);
    // await OutreachCampaignTest.deleteCampaigns(tester); // Delete not implemented in UI yet
  }, skip: false);
}
