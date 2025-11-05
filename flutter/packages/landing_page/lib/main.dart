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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'views/configurable_landing_page.dart';
import 'src/screens/landing_page_assessment_flow_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String classificationId = GlobalConfiguration().get("classificationId");
  // check if there is override for the production(now test) backend url
  await getBackendUrlOverride(classificationId, packageInfo.version);

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());

  // this part is only executing on the web
  Company? company;
  final uri = Uri.base;
  debugPrint("=====Uri.base: ${Uri.base} host: ${uri.host}");
  try {
    company = await restClient.getCompanyFromHost(uri.host);
  } on DioException catch (e) {
    debugPrint("getting hostname error: ${await getDioError(e)}");
  }

  final query = uri.queryParameters;
  String? landingPageId = query['landingPageId'];
  String pseudoId = query['pseudoId'] ?? query['pageId'] ?? 'erp-landing-page';
  String? ownerPartyId = company?.ownerPartyId ?? 'GROWERP';

  debugPrint('=== landing page landingPageId: $landingPageId');
  debugPrint('=== landing page pseudoId: $pseudoId');
  debugPrint('=== ownerPartyId: $ownerPartyId');

  runApp(
    PublicLandingPageApp(
      restClient: restClient,
      classificationId: classificationId,
      landingPageId: landingPageId,
      pseudoId: pseudoId,
      ownerPartyId: ownerPartyId,
    ),
  );
}

List<LocalizationsDelegate> delegates = [];

List<BlocProvider> getLandingPageBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [...getAssessmentBlocProviders(restClient, classificationId)];
}

class PublicLandingPageApp extends StatelessWidget {
  const PublicLandingPageApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    this.pseudoId,
    this.landingPageId,
    this.ownerPartyId,
  });

  final RestClient restClient;
  final String classificationId;
  final String? pseudoId;
  final String? landingPageId;
  final String? ownerPartyId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getLandingPageBlocProviders(restClient, classificationId),
      child: MaterialApp(
        title: 'GrowERP Landing Page',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        localizationsDelegates: [
          CoreLocalizations.delegate,
          ...delegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: CoreLocalizations.supportedLocales,
        home: ConfigurableLandingPage(
          pseudoId: pseudoId ?? '',
          landingPageId: landingPageId,
          ownerPartyId: ownerPartyId,
        ),
        routes: {
          '/assessment': (context) => LandingPageAssessmentFlowScreen(
            landingPageId: landingPageId ?? '',
            ownerPartyId: ownerPartyId,
            startAssessmentFlow: true,
          ),
        },
      ),
    );
  }
}
