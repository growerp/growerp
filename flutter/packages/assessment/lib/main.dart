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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_interop' if (dart.library.io) 'dart:js_interop';
import 'package:web/web.dart' as web if (dart.library.io) 'package:web/web.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");
  // check if there is override for the production(now test) backend url
  await getBackendUrlOverride(applicationId, packageInfo.version);

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

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

  debugPrint('=== assessment app - landingPageId: $landingPageId');
  debugPrint('=== assessment app - pseudoId: $pseudoId');
  debugPrint('=== assessment app - ownerPartyId: $ownerPartyId');

  runApp(
    AssessmentApp(
      restClient: restClient,
      chatClient: chatClient,
      notificationClient: notificationClient,
      applicationId: applicationId,
      landingPageId: landingPageId,
      pseudoId: pseudoId,
      ownerPartyId: ownerPartyId,
      company: company,
    ),
  );

  // Notify parent window that Flutter app is ready (for iframe embedding)
  // Use a small delay to ensure the first frame is rendered
  Future.delayed(const Duration(milliseconds: 100), () {
    notifyFlutterReady();
  });
}

List<LocalizationsDelegate> delegates = [];

/// Notify parent window that Flutter app is ready (for iframe embedding)
void notifyFlutterReady() {
  if (kIsWeb) {
    try {
      final message = {'type': 'flutter-ready'}.jsify();
      web.window.parent?.postMessage(message, '*'.toJS);
      debugPrint('=== Sent flutter-ready message to parent window');
    } catch (e) {
      debugPrint('=== Could not send flutter-ready message: $e');
    }
  }
}

// Get BLoC providers for the assessment app
List<BlocProvider> getAssessmentAppBlocProviders(
  RestClient restClient,
  WsClient chatClient,
  WsClient notificationClient,
  String applicationId,
  Company? company,
) {
  // Combine core BLoCs with assessment-specific BLoCs
  return [
    ...getCoreBlocProviders(
      restClient,
      chatClient,
      notificationClient,
      applicationId,
      company,
    ),
    ...getMarketingBlocProviders(restClient, applicationId),
  ];
}

class AssessmentApp extends StatelessWidget {
  const AssessmentApp({
    super.key,
    required this.restClient,
    required this.chatClient,
    required this.notificationClient,
    required this.applicationId,
    this.pseudoId,
    this.landingPageId,
    this.ownerPartyId,
    this.company,
  });

  final RestClient restClient;
  final WsClient chatClient;
  final WsClient notificationClient;
  final String applicationId;
  final String? pseudoId;
  final String? landingPageId;
  final String? ownerPartyId;
  final Company? company;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getAssessmentAppBlocProviders(
        restClient,
        chatClient,
        notificationClient,
        applicationId,
        company,
      ),
      child: MaterialApp(
        title: 'GrowERP Assessment',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        localizationsDelegates: [
          CoreLocalizations.delegate,
          ...delegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: CoreLocalizations.supportedLocales,
        home: LandingPageAssessmentFlowScreen(
          landingPageId: pseudoId ?? landingPageId ?? '',
          ownerPartyId: ownerPartyId,
          startAssessmentFlow: true,
        ),
      ),
    );
  }
}
