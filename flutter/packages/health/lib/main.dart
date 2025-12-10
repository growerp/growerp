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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_activity/growerp_activity.dart';

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'views/health_dashboard.dart';
import 'package:package_info_plus/package_info_plus.dart';
//webactivate import 'package:web/web.dart' as web;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String classificationId = GlobalConfiguration().get("classificationId");

  await getBackendUrlOverride(classificationId, packageInfo.version);

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
    HealthApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      extraDelegates: delegates,
      company: company,
    ),
  );
}

class HealthApp extends StatefulWidget {
  const HealthApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    required this.extraDelegates,
    this.company,
  });

  final RestClient restClient;
  final String classificationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final List<LocalizationsDelegate> extraDelegates;
  final Company? company;

  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'health');
  }

  @override
  void dispose() {
    _menuConfigBloc.close();
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
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Health',
                // No accounting submenu for health app
              ),
            );
          } else {
            // Loading or error, show splash screen using shared component
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Health',
                    appId: 'health',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            restClient: widget.restClient,
            classificationId: widget.classificationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP Health',
            router: router,
            extraDelegates: widget.extraDelegates,
            extraBlocProviders: getHealthBlocProviders(
              widget.restClient,
              widget.classificationId,
            ),
            company: widget.company,
            widgetRegistrations: healthWidgetRegistrations,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  ActivityLocalizations.delegate,
];

/// Widget registrations for all packages used by Health app
List<Map<String, GrowerpWidgetBuilder>> healthWidgetRegistrations = [
  getUserCompanyWidgets(),
  getOrderAccountingWidgets(),
  getActivityWidgets(),
  getSalesWidgets(),
  getWebsiteWidgets(),
  // App-specific widgets
  {
    'HealthDashboard': (args) => const HealthDashboard(),
    'AboutForm': (args) => const AboutForm(),
  },
];

List<BlocProvider> getHealthBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, classificationId),
    ...getSalesBlocProviders(restClient),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
    ...getWebsiteBlocProviders(restClient),
  ];
}
