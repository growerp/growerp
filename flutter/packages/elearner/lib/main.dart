// ignore_for_file: depend_on_referenced_packages

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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:package_info_plus/package_info_plus.dart';
//webactivate  import 'package:web/web.dart' as web;

import 'views/elearner_dashboard.dart';
import 'views/elearner_splash_screen.dart';
import 'views/elearner_participant_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  final packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  final classificationId = GlobalConfiguration().get('classificationId') as String;
  final forceUpdateInfo = await getBackendUrlOverride(
    classificationId,
    packageInfo.version,
  );

  Bloc.observer = AppBlocObserver();
  final restClient = RestClient(await buildDioClient());
  final chatClient = WsClient('chat');
  final notificationClient = WsClient('notws');

  Company? company;
  if (kIsWeb) {
    String? hostName;
    //webactivate  hostName = web.window.location.hostname;
    // ignore: unnecessary_null_comparison
    if (hostName != null) {
      try {
        company = await restClient.getCompanyFromHost(hostName);
      } on DioException catch (e) {
        debugPrint('getting hostname error: ${await getDioError(e)}');
      }
      if (company?.partyId == null) company = null;
    }
  }

  runApp(
    ElearnerApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class ElearnerApp extends StatefulWidget {
  const ElearnerApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    this.company,
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String classificationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final Company? company;
  final ForceUpdateInfo? forceUpdateInfo;

  @override
  State<ElearnerApp> createState() => _ElearnerAppState();
}

class _ElearnerAppState extends State<ElearnerApp> {
  late MenuConfigBloc _menuConfigBloc;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'elearner');
  }

  @override
  void dispose() {
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
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP eLearner',
                deepLinkService: _deepLinkService,
              ),
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) =>
                      const ElearnerSplashScreen(),
                ),
              ],
            );
          }

          return TopApp(
            restClient: widget.restClient,
            classificationId: widget.classificationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP eLearner',
            router: router,
            extraDelegates: _delegates,
            extraBlocProviders: getElearnerBlocProviders(
              widget.restClient,
              widget.classificationId,
            ),
            company: widget.company,
            widgetRegistrations: elearnerWidgetRegistrations,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

final List<LocalizationsDelegate> _delegates = [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
];

/// Widget registrations for the eLearner app.
List<Map<String, GrowerpWidgetBuilder>> elearnerWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCoursesWidgets(),
  getCatalogWidgets(),
  getWebsiteWidgets(),
  {
    'AboutForm': (args) => const AboutForm(),
    'ElearnerDashboard': (args) => const ElearnerDashboard(),
    'ElearnerParticipantList': (args) => const ElearnerParticipantList(),
  },
];

List<BlocProvider> getElearnerBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, classificationId),
    ...getCoursesBlocProviders(restClient),
    ...getCatalogBlocProviders(restClient, classificationId),
    ...getWebsiteBlocProviders(restClient),
  ];
}
