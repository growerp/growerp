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

// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_rental/growerp_rental.dart';

import 'views/accounting_form.dart';
import 'views/housekeeping_form.dart';
import 'l10n/generated/hotel_localizations.dart';
import 'package:growerp_adk/growerp_adk.dart';

Future main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");
  // check if there is override for the production(now test) backend url
  // Also checks if force update is required
  final forceUpdateInfo = await getBackendUrlOverride(
    applicationId,
    packageInfo.version,
  );

  // Set date offset for testing (rental, subscription expiration, etc.)
  // Change to non-zero value to test time-dependent features, e.g., 15
  setTestDaysOffset(0);

  Bloc.observer = AppBlocObserver();
  debugPrint("=== current date: ${CustomizableDateTime.current}");

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  Bloc.observer = AppBlocObserver();
  Company? company = await getStartupCompany(restClient, args: args);

  runApp(
    HotelApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class HotelApp extends StatefulWidget {
  const HotelApp({
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
  State<HotelApp> createState() => _HotelAppState();
}

class _HotelAppState extends State<HotelApp> {
  late MenuConfigBloc _menuConfigBloc;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize MenuConfigBloc with AppID 'hotel'
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'hotel');
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
                mainConfigId: 'HOTEL_DEFAULT',
                dashboardBuilder: () => const GanttForm(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Hotel',
                deepLinkService: _deepLinkService,
              ),
              rootNavigatorKey: GlobalKey<NavigatorState>(),
            );
          } else {
            // Loading or error, show splash screen using shared component
            // The wildcard route ensures deep-link paths are accepted and
            // preserved while the menu config loads.
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Hotel',
                    appId: 'hotel',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Hotel',
                    appId: 'hotel',
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
            title: 'GrowERP Hotel.',
            router: router,
            extraDelegates: delegates,
            extraBlocProviders: getHotelBlocProviders(
              widget.restClient,
              widget.applicationId,
            ),
            company: widget.company,
            widgetRegistrations: hotelWidgetRegistrations,
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
  InventoryLocalizations.delegate,
  CatalogLocalizations.delegate,
  ActivityLocalizations.delegate,
  RentalLocalizations.delegate,
  HotelLocalizations.delegate,
  AdkLocalizations.delegate,
];

/// Widget registrations for all packages used by Hotel app
List<Map<String, GrowerpWidgetBuilder>> hotelWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getOrderAccountingWidgets(),
  getWebsiteWidgets(),
  getRentalWidgets(),
  // App-specific widgets
  {
    'AccountingForm': (args) => const AccountingForm(),
    'HousekeepingForm': (args) => const HousekeepingForm(),
  },
];

List<BlocProvider> getHotelBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getInventoryBlocProviders(restClient, applicationId),
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getCatalogBlocProviders(restClient, applicationId),
    ...getOrderAccountingBlocProviders(restClient, applicationId),
    ...getSalesBlocProviders(restClient),
    ...getWebsiteBlocProviders(restClient),
  ];
}
