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

import 'package:flutter/foundation.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_adk/growerp_adk.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_wiki/growerp_wiki.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:growerp_demos/growerp_demos.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'views/admin_dashboard_content.dart';
import 'views/plan_selection_form.dart';
import 'views/accounting_form.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'l10n/generated/admin_localizations.dart';

Future main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  // Set date offset for testing (rental, subscription expiration, etc.)
  // Change to non-zero value to test time-dependent features, e.g., 15
  setTestDaysOffset(0);

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");

  // check if there is override for the production backend url
  // if there is a overide we are in test mode: see the banner in the app
  // Also checks if force update is required
  final forceUpdateInfo = await getBackendUrlOverride(
    applicationId,
    packageInfo.version,
  );

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  Company? company = await getStartupCompany(restClient, args: args);

  runApp(
    AdminApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      extraDelegates: delegates,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class AdminApp extends StatefulWidget {
  const AdminApp({
    super.key,
    required this.restClient,
    required this.applicationId,
    required this.chatClient,
    required this.notificationClient,
    required this.extraDelegates,
    this.company,
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String applicationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final List<LocalizationsDelegate> extraDelegates;
  final Company? company;
  final ForceUpdateInfo? forceUpdateInfo;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late MenuConfigBloc _menuConfigBloc;
  final DeepLinkService _deepLinkService = DeepLinkService();

  // Routers are kept per menu configuration: rebuilding them on every
  // MenuConfigBloc state change handed MaterialApp.router a new delegate each
  // time (and threw the user back to the splash screen during a menu reload).
  GoRouter? _splashRouter;
  GoRouter? _dynamicRouter;
  String? _dynamicRouterKey;

  @override
  void initState() {
    super.initState();
    // Initialize MenuConfigBloc with AppID 'admin'
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'admin');
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

          final menuConfiguration = state.menuConfiguration;
          if (menuConfiguration != null) {
            // Configuration loaded, build dynamic router using shared component
            final routerKey =
                '${menuConfiguration.menuConfigurationId}_'
                '${menuConfiguration.menuItems.length}';
            if (_dynamicRouter == null || _dynamicRouterKey != routerKey) {
              _dynamicRouterKey = routerKey;
              _dynamicRouter = createDynamicAppRouter(
                [menuConfiguration],
                config: DynamicRouterConfig(
                  mainConfigId: 'ADMIN_DEFAULT',
                  dashboardBuilder: () => const AdminDashboardContent(),
                  widgetLoader: WidgetRegistry.getWidget,
                  appTitle: 'GrowERP Administrator',
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
            }
            router = _dynamicRouter!;
          } else {
            // Loading or error, show splash screen using shared component
            // The wildcard route ensures deep-link paths (e.g. #/acct-ledger)
            // are accepted and preserved while the menu config loads.
            router = _splashRouter ??= GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Administrator',
                    appId: 'admin',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Administrator',
                    appId: 'admin',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            // Key forces a complete rebuild when the menu config changes
            // (e.g. the user-specific menu loaded after authentication), so the
            // subtree re-reads fresh AuthBloc state. Matches the core example.
            key: ValueKey(
              '${state.menuConfiguration?.menuConfigurationId ?? ''}_'
              '${state.menuConfiguration?.menuItems.length ?? 0}',
            ),
            restClient: widget.restClient,
            applicationId: widget.applicationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP Administrator',
            router: router,
            extraDelegates: widget.extraDelegates,
            extraBlocProviders: getAdminBlocProviders(
              widget.restClient,
              widget.applicationId,
            ),
            company: widget.company,
            widgetRegistrations: adminWidgetRegistrations,
            widgetMetadata: adminWidgetMetadata,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  ManufacturingLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  SalesLocalizations.delegate,
  ActivityLocalizations.delegate,
  WikiLocalizations.delegate,
  DemosLocalizations.delegate,
  ManufLinerLocalizations.delegate,
  MarketingLocalizations.delegate,
  OutreachLocalizations.delegate,
  AdminLocalizations.delegate,
  AdkLocalizations.delegate,
  CoursesLocalizations.delegate,
];

/// Widget registrations for all packages used by Admin app
List<Map<String, GrowerpWidgetBuilder>> adminWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getManufacturingWidgets(),
  getOrderAccountingWidgets(),
  getActivityWidgets(),
  getMarketingWidgets(),
  getOutreachWidgets(),
  getSalesWidgets(),
  getWebsiteWidgets(),
  getWikiWidgets(),
  getCoursesWidgets(),
  // App-specific widgets
  {
    'AdminDashboard': (args) => const AdminDashboardContent(),
    'AccountingForm': (args) => const AccountingForm(),
    'PlanSelectionForm': (args) => const PlanSelectionForm(),
    'AboutForm': (args) => const AboutForm(),
    'AdkAgentListView': (args) => const AdkAgentListView(),
    'AdkMcpServerListView': (args) => const AdkMcpServerListView(),
    'AdkJobListView': (args) => const AdkJobListView(),
    'AdkApprovalsListView': (args) => const AdkApprovalsListView(),
    'AdkActionsListView': (args) => const AdkActionsListView(),
    'AdkKnowledgeView': (args) => const AdkKnowledgeView(),
    // Demo widget — only registered outside production builds
    if (!kReleaseMode) 'DemoList': (args) => const DemoListScreen(),
  },
];

/// Rich widget metadata for AI navigation (descriptions/keywords/parameters).
/// Registered after [adminWidgetRegistrations] to enrich the screen catalog the
/// ADK agent uses to emit navigation directives.
List<WidgetMetadata> adminWidgetMetadata = [
  ...getUserCompanyWidgetsWithMetadata(),
  ...getCatalogWidgetsWithMetadata(),
  ...getInventoryWidgetsWithMetadata(),
  ...getManufacturingWidgetsWithMetadata(),
  ...getOrderAccountingWidgetsWithMetadata(),
  ...getActivityWidgetsWithMetadata(),
  ...getMarketingWidgetsWithMetadata(),
  ...getOutreachWidgetsWithMetadata(),
  ...getSalesWidgetsWithMetadata(),
  ...getWebsiteWidgetsWithMetadata(),
  ...getWikiWidgetsWithMetadata(),
  ...getCoursesWidgetsWithMetadata(),
];

List<BlocProvider> getAdminBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getInventoryBlocProviders(restClient, applicationId),
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getCatalogBlocProviders(restClient, applicationId),
    ...getManufacturingBlocProviders(restClient),
    ...getLinerBlocProviders(restClient),
    ...getOrderAccountingBlocProviders(restClient, applicationId),
    ...getSalesBlocProviders(restClient),
    ...getMarketingBlocProviders(restClient),
    ...getOutreachBlocProviders(restClient),
    ...getWebsiteBlocProviders(restClient),
    ...getCoursesBlocProviders(restClient),
  ];
}
