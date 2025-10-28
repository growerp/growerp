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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
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

  // can change backend url by pressing long the title on the home screen.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String classificationId = GlobalConfiguration().get("classificationId");
  // check if there is override for the production(now test) backend url
  await getBackendUrlOverride(classificationId, packageInfo.version);

  String ip = prefs.getString('ip') ?? '';
  String chat = prefs.getString('chat') ?? '';
  String singleCompany = prefs.getString('companyPartyId') ?? '';
  if (ip.isNotEmpty) {
    late http.Response response;
    try {
      response = await http.get(Uri.parse('${ip}rest/s1/growerp/Ping'));
      if (response.statusCode == 200) {
        GlobalConfiguration().updateValue('databaseUrl', ip);
        GlobalConfiguration().updateValue('chatUrl', chat);
        GlobalConfiguration().updateValue('singleCompany', singleCompany);
        debugPrint(
          '=== New ip: $ip , chat: $chat company: $singleCompany Updated!',
        );
      }
    } catch (error) {
      debugPrint('===$ip does not respond...not updating databaseUrl: $error');
    }
  }

  final routeInfo = _resolveLandingPageRoute(
    defaultOwnerPartyId: singleCompany.isNotEmpty ? singleCompany : null,
  );

  if (routeInfo.ownerPartyId != null && routeInfo.ownerPartyId!.isNotEmpty) {
    GlobalConfiguration().updateValue('singleCompany', routeInfo.ownerPartyId);
    await prefs.setString('companyPartyId', routeInfo.ownerPartyId!);
  }

  if (kIsWeb && ip.isEmpty) {
    final baseUri = Uri.base;
    final origin = baseUri.origin;
    GlobalConfiguration().updateValue('databaseUrl', origin);

    final wsScheme = origin.startsWith('https') ? 'wss' : 'ws';
    final hostWithPort = baseUri.hasPort
        ? '${baseUri.host}:${baseUri.port}'
        : baseUri.host;
    final wsEndpoint = '$wsScheme://$hostWithPort';
    GlobalConfiguration().updateValue('chatUrl', '$wsEndpoint/chat');
    GlobalConfiguration().updateValue('chatUrlDebug', '$wsEndpoint/chat');
  }

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());

  runApp(
    PublicLandingPageApp(
      restClient: restClient,
      classificationId: classificationId,
      initialPageId: 'erp-landing', //' routeInfo.pageId, // test: 'erp-landing'
      ownerPartyId: '100000', //routeInfo.ownerPartyId, // test '100000'
      initialAssessmentId: routeInfo.assessmentId,
      startAssessmentFlow: routeInfo.startAssessmentFlow,
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
    required this.initialPageId,
    this.ownerPartyId,
    this.initialAssessmentId,
    this.startAssessmentFlow = false,
  });

  final RestClient restClient;
  final String classificationId;
  final String initialPageId;
  final String? ownerPartyId;
  final String? initialAssessmentId;
  final bool startAssessmentFlow;

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
        initialRoute: startAssessmentFlow ? '/assessment' : '/',
        home: ConfigurableLandingPage(
          pageId: initialPageId,
          ownerPartyId: ownerPartyId,
        ),
        routes: {
          '/assessment': (context) => LandingPageAssessmentFlowScreen(
            pageId: initialPageId,
            ownerPartyId: ownerPartyId,
            assessmentId: initialAssessmentId ?? 'default-assessment',
          ),
        },
      ),
    );
  }
}

class _LandingRouteInfo {
  const _LandingRouteInfo({
    required this.pageId,
    this.ownerPartyId,
    this.assessmentId,
    this.startAssessmentFlow = false,
  });

  final String pageId;
  final String? ownerPartyId;
  final String? assessmentId;
  final bool startAssessmentFlow;
}

_LandingRouteInfo _resolveLandingPageRoute({String? defaultOwnerPartyId}) {
  String pageId = 'default';
  String? ownerPartyId = defaultOwnerPartyId;
  String? assessmentId;
  bool startAssessmentFlow = false;

  if (kIsWeb) {
    final uri = Uri.base;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i].toLowerCase();
      if (segment == 'landingpage' && i + 1 < segments.length) {
        pageId = segments[i + 1];
        if (i + 2 < segments.length &&
            segments[i + 2].toLowerCase() == 'assessment') {
          startAssessmentFlow = true;
        }
      } else if (segment == 'assessment') {
        startAssessmentFlow = true;
      }
    }

    final query = uri.queryParameters;
    pageId = query['pageId'] ?? pageId;
    ownerPartyId = query['ownerPartyId'] ?? ownerPartyId;
    assessmentId = query['assessmentId'] ?? assessmentId;
    if (query['flow']?.toLowerCase() == 'assessment') {
      startAssessmentFlow = true;
    }

    final hostParts = uri.host.split('.');
    if (hostParts.length >= 2) {
      final candidate = hostParts.first;
      final candidateLower = candidate.toLowerCase();
      if (candidate.isNotEmpty &&
          candidateLower != 'www' &&
          candidateLower != 'app' &&
          candidateLower != 'admin' &&
          candidateLower != 'landingpage' &&
          candidateLower != 'store' &&
          candidateLower != 'localhost') {
        ownerPartyId = candidate;
      } else if (hostParts.last.toLowerCase() == 'localhost' &&
          candidateLower != 'localhost' &&
          candidate.isNotEmpty) {
        ownerPartyId = candidate;
      }
    }
  }

  if (pageId.isEmpty) {
    pageId = 'default';
  }

  return _LandingRouteInfo(
    pageId: pageId,
    ownerPartyId: ownerPartyId,
    assessmentId: assessmentId,
    startAssessmentFlow: startAssessmentFlow,
  );
}
