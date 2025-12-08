// ignore_for_file: depend_on_referenced_packages, avoid_print

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

import 'src/application/application.dart';
import 'views/support_dashboard.dart';
//webactivate  import 'package:web/web.dart' as web;

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
      print("=====hostname: $hostName");
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
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
    ),
  );
}

class SupportApp extends StatefulWidget {
  const SupportApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    this.company,
  });

  final RestClient restClient;
  final String classificationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final Company? company;

  @override
  State<SupportApp> createState() => _SupportAppState();
}

class _SupportAppState extends State<SupportApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'support');
    _menuConfigBloc.add(const MenuConfigLoad());
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
                appTitle: 'GrowERP Support',
              ),
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
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
            title: 'GrowERP System Support.',
            router: router,
            extraDelegates: delegates,
            extraBlocProviders: getSupportBlocProviders(
              widget.restClient,
              widget.classificationId,
            ),
            company: widget.company,
            widgetRegistrations: supportWidgetRegistrations,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  ActivityLocalizations.delegate,
];

/// Widget registrations for all packages used by Support app
List<Map<String, GrowerpWidgetBuilder>> supportWidgetRegistrations = [
  getUserCompanyWidgets(),
  getActivityWidgets(),
  // App-specific widgets
  {
    'SupportDashboard': (args) => const SupportDashboard(),
    'AboutForm': (args) => const AboutForm(),
  },
];

List<BlocProvider> getSupportBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, classificationId),
    BlocProvider<ApplicationBloc>(
      create: (context) => ApplicationBloc(restClient),
    ),
    BlocProvider<RestRequestBloc>(
      create: (context) => RestRequestBloc(restClient),
    ),
  ];
}
