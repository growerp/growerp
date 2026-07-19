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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_adk/growerp_adk.dart';
import 'package:growerp_wiki/growerp_wiki.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'views/marketing_db_form.dart';
//webactivate  import 'package:web/web.dart' as web;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");
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
      try {
        company = await restClient.getCompanyFromHost(hostName);
      } on DioException catch (e) {
        debugPrint("getting hostname error: ${await getDioError(e)}");
      }
      if (company?.partyId == null) company = null;
    }
  }

  runApp(
    MarketingApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class MarketingApp extends StatefulWidget {
  const MarketingApp({
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
  State<MarketingApp> createState() => _MarketingAppState();
}

class _MarketingAppState extends State<MarketingApp> {
  late MenuConfigBloc _menuConfigBloc;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'marketing');
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
                mainConfigId: 'MARKETING_DEFAULT',
                dashboardBuilder: () => const MarketingDbForm(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Marketing',
                deepLinkService: _deepLinkService,
                dashboardFabBuilder: (_) => Builder(
                  builder: (ctx) => FloatingActionButton(
                    key: const Key('adkChatFab'),
                    tooltip: 'AI Assistant',
                    onPressed: () => AdkChatDialog.show(ctx),
                    child: const Icon(Icons.smart_toy),
                  ),
                ),
              ),
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Marketing',
                    appId: 'marketing',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Marketing',
                    appId: 'marketing',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            key: ValueKey(
              '${state.menuConfiguration?.menuConfigurationId ?? ''}_'
              '${state.menuConfiguration?.menuItems.length ?? 0}',
            ),
            restClient: widget.restClient,
            applicationId: widget.applicationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP Marketing',
            router: router,
            extraDelegates: const [
              UserCompanyLocalizations.delegate,
              SalesLocalizations.delegate,
              OrderAccountingLocalizations.delegate,
              WebsiteLocalizations.delegate,
              ActivityLocalizations.delegate,
            ],
            extraBlocProviders: [
              ...getUserCompanyBlocProviders(
                  widget.restClient, widget.applicationId),
              ...getSalesBlocProviders(widget.restClient),
              ...getOrderAccountingBlocProviders(
                  widget.restClient, widget.applicationId),
              ...getMarketingBlocProviders(widget.restClient),
              ...getOutreachBlocProviders(widget.restClient),
              ...getWebsiteBlocProviders(widget.restClient),
              ...getActivityBlocProviders(
                  widget.restClient, widget.applicationId),
            ],
            company: widget.company,
            widgetRegistrations: marketingWidgetRegistrations,
            widgetMetadata: marketingWidgetMetadata,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

/// Widget registrations for all packages used by the Marketing app.
List<Map<String, GrowerpWidgetBuilder>> marketingWidgetRegistrations = [
  getUserCompanyWidgets(),
  getSalesWidgets(),
  getOrderAccountingWidgets(),
  getMarketingWidgets(),
  getOutreachWidgets(),
  getWebsiteWidgets(),
  getActivityWidgets(),
  getWikiWidgets(),
  // App-specific widgets
  {
    'MarketingDbForm': (args) => const MarketingDbForm(),
    'AboutForm': (args) => const AboutForm(),
    'AdkAgentListView': (args) => const AdkAgentListView(),
    'AdkMcpServerListView': (args) => const AdkMcpServerListView(),
    'AdkJobListView': (args) => const AdkJobListView(),
    'AdkApprovalsListView': (args) => const AdkApprovalsListView(),
    'AdkActionsListView': (args) => const AdkActionsListView(),
    'AdkKnowledgeView': (args) => const AdkKnowledgeView(),
  },
];

/// Rich widget metadata for AI navigation.
List<WidgetMetadata> marketingWidgetMetadata = [
  ...getUserCompanyWidgetsWithMetadata(),
  ...getSalesWidgetsWithMetadata(),
  ...getOrderAccountingWidgetsWithMetadata(),
  ...getMarketingWidgetsWithMetadata(),
  ...getOutreachWidgetsWithMetadata(),
  ...getWebsiteWidgetsWithMetadata(),
  ...getActivityWidgetsWithMetadata(),
  ...getWikiWidgetsWithMetadata(),
];
