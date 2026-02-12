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
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'views/admin_dashboard_content.dart';
import 'views/plan_selection_form.dart';
import 'views/accounting_form.dart';
import 'package:package_info_plus/package_info_plus.dart';
//webactivate  import 'package:web/web.dart' as web;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set date offset for testing (rental, subscription expiration, etc.)
  // Change to non-zero value to test time-dependent features, e.g., 15
  setTestDaysOffset(0);

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String classificationId = GlobalConfiguration().get("classificationId");

  // check if there is override for the production backend url
  // if there is a overide we are in test mode: see the banner in the app
  // Also checks if force update is required
  final forceUpdateInfo = await getBackendUrlOverride(
    classificationId,
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
    AdminApp(
      restClient: restClient,
      classificationId: classificationId,
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
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    required this.extraDelegates,
    this.company,
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String classificationId;
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

          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            // Configuration loaded, build dynamic router using shared component
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                mainConfigId: 'ADMIN_DEFAULT',
                dashboardBuilder: () => const AdminDashboardContent(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Administrator',
                dashboardFabBuilder: (menuConfig) => Builder(
                  builder: (fabContext) => FloatingActionButton(
                    key: const Key('menuFab'),
                    heroTag: 'menuFab',
                    tooltip: 'Manage Menu Items',
                    onPressed: () {
                      showDialog(
                        context: fabContext,
                        builder: (dialogContext) => BlocProvider.value(
                          value: fabContext.read<MenuConfigBloc>(),
                          child: MenuItemListDialog(
                            menuConfiguration: menuConfig,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.menu),
                  ),
                ),
                deepLinkService: _deepLinkService,
              ),
            );
          } else {
            // Loading or error, show splash screen using shared component
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Administrator',
                    appId: 'admin',
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
            title: 'GrowERP Administrator',
            router: router,
            extraDelegates: widget.extraDelegates,
            extraBlocProviders: getAdminBlocProviders(
              widget.restClient,
              widget.classificationId,
            ),
            company: widget.company,
            widgetRegistrations: adminWidgetRegistrations,
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
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  SalesLocalizations.delegate,
  ActivityLocalizations.delegate,
];

/// Widget registrations for all packages used by Admin app
List<Map<String, GrowerpWidgetBuilder>> adminWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getOrderAccountingWidgets(),
  getActivityWidgets(),
  getMarketingWidgets(),
  getOutreachWidgets(),
  getSalesWidgets(),
  getWebsiteWidgets(),
  getCoursesWidgets(),
  // App-specific widgets
  {
    'AdminDashboard': (args) => const AdminDashboardContent(),
    'AccountingForm': (args) => const AccountingForm(),
    'PlanSelectionForm': (args) => const PlanSelectionForm(),
    'AboutForm': (args) => const AboutForm(),
  },
];

List<BlocProvider> getAdminBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getInventoryBlocProviders(restClient, classificationId),
    ...getUserCompanyBlocProviders(restClient, classificationId),
    ...getCatalogBlocProviders(restClient, classificationId),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
    ...getSalesBlocProviders(restClient),
    ...getMarketingBlocProviders(restClient),
    ...getOutreachBlocProviders(restClient),
    ...getWebsiteBlocProviders(restClient),
    ...getCoursesBlocProviders(restClient),
  ];
}
