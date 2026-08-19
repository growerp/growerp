// ignore_for_file: depend_on_referenced_packages

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
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_adk/growerp_adk.dart';

import 'src/application/application.dart';
import 'src/website_conversion/website_conversion.dart';
import 'src/gl_account_translation/gl_account_translation.dart';
import 'src/website_translation/website_translation.dart';
import 'src/system_defaults/system_defaults.dart';
import 'views/rest_statistics_view.dart';
import 'views/support_dashboard_content.dart';
import 'l10n/generated/support_localizations.dart';
//webactivate  import 'package:web/web.dart' as web;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");
  // Also checks if force update is required
  final forceUpdateInfo = await getBackendUrlOverride(
    applicationId,
    packageInfo.version,
  );

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  Company? company;
  if (kIsWeb) {
    String? hostName;
    //webactivate  hostName = web.window.location.hostname;
    // ignore: unnecessary_null_comparison
    if (hostName != null) {
      debugPrint("=====hostname: $hostName");
      try {
        company = await restClient.getCompanyFromHost(hostName);
      } on DioException catch (e) {
        debugPrint("getting hostname error: ${await getDioError(e)}");
      }
      if (company?.partyId == null) company = null;
    }
  }

  runApp(
    SupportApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class SupportApp extends StatefulWidget {
  const SupportApp({
    super.key,
    required this.restClient,
    required this.applicationId,
    required this.chatClient,
    required this.notificationClient,
    this.company,
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String applicationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final Company? company;
  final ForceUpdateInfo? forceUpdateInfo;

  @override
  State<SupportApp> createState() => _SupportAppState();
}

class _SupportAppState extends State<SupportApp> {
  late MenuConfigBloc _menuConfigBloc;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'support');
  }

  @override
  void dispose() {
    // Close WebSocket connections gracefully to avoid backend ClosedChannelException
    widget.chatClient.close();
    widget.notificationClient.close();
    _menuConfigBloc.close();
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _menuConfigBloc,
      child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
        builder: (context, state) {
          GoRouter router;

          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            // Use simplified config - no accounting submenu
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                dashboardBuilder: () => const SupportDashboardContent(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Support',
                deepLinkService: _deepLinkService,
              ),
            );
          } else {
            // Loading or error, show splash screen using shared component
            // The wildcard route ensures deep-link paths are accepted and
            // preserved while the menu config loads.
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Support',
                    appId: 'support',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Support',
                    appId: 'support',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            restClient: widget.restClient,
            applicationId: widget.applicationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP System Support.',
            router: router,
            extraDelegates: delegates,
            extraBlocProviders: getSupportBlocProviders(
              widget.restClient,
              widget.applicationId,
            ),
            company: widget.company,
            widgetRegistrations: supportWidgetRegistrations,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  ActivityLocalizations.delegate,
  SupportLocalizations.delegate,
];

List<Map<String, GrowerpWidgetBuilder>> supportWidgetRegistrations = [
  getUserCompanyWidgets(),
  getActivityWidgets(),
  // App-specific widgets
  {
    'AboutForm': (args) => const AboutForm(),
    'ApplicationList': (args) => const ApplicationList(),
    'AdkSystemUsageView': (args) => const AdkSystemUsageView(),
    'RestStatisticsView': (args) => const RestStatisticsView(),
    'WebsiteConversionList': (args) => const WebsiteConversionList(),
    'WebsiteTranslationList': (args) => const WebsiteTranslationList(),
    'GlAccountTranslationList': (args) => const GlAccountTranslationList(),
    'SystemDefaultsDialog': (args) => const SystemDefaultsDialog(),
  },
];

List<BlocProvider> getSupportBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    BlocProvider<ApplicationBloc>(
      create: (context) => ApplicationBloc(restClient),
    ),
    BlocProvider<WebsiteConversionBloc>(
      create: (context) => WebsiteConversionBloc(restClient),
    ),
    BlocProvider<WebsiteTranslationBloc>(
      create: (context) => WebsiteTranslationBloc(restClient),
    ),
    BlocProvider<GlAccountTranslationBloc>(
      create: (context) => GlAccountTranslationBloc(restClient),
    ),
  ];
}
