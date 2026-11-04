// ignore_for_file: depend_on_referenced_packages, avoid_print

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  final forceUpdateInfo = await getBackendUrlOverride(
    applicationId,
    packageInfo.version,
  );

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  // optional company: --companyPartyId= on the command line, ?companyPartyId=
  // in the url, a deeplink or the singleCompany app_settings key
  Company? company = await getStartupCompany(restClient, args: args);

  runApp(
    RestaurantApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class RestaurantApp extends StatefulWidget {
  const RestaurantApp({
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
  State<RestaurantApp> createState() => _RestaurantAppState();
}

class _RestaurantAppState extends State<RestaurantApp> {
  late MenuConfigBloc _menuConfigBloc;
  // Routers are kept per menu configuration: building a new GoRouter on every
  // MenuConfigBloc emission hands MaterialApp.router a new delegate, which
  // rebuilds the navigator and silently drops the dialogs open on it.
  GoRouter? _splashRouter;
  GoRouter? _dynamicRouter;
  String? _dynamicRouterKey;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'restaurant');
  }

  @override
  void dispose() {
    widget.chatClient.close();
    widget.notificationClient.close();
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

          final menuConfiguration = state.menuConfiguration;
          if (state.status == MenuConfigStatus.success &&
              menuConfiguration != null) {
            final routerKey =
                '${menuConfiguration.menuConfigurationId}_'
                '${menuConfiguration.menuItems.length}';
            if (_dynamicRouter == null || _dynamicRouterKey != routerKey) {
              _dynamicRouterKey = routerKey;
              _dynamicRouter = createDynamicAppRouter(
                [menuConfiguration],
                config: DynamicRouterConfig(
                  mainConfigId: 'RESTAURANT_DEFAULT',
                  dashboardBuilder: () => const PosFloorScreen(),
                  widgetLoader: WidgetRegistry.getWidget,
                  appTitle: 'GrowERP Restaurant',
                ),
              );
            }
            router = _dynamicRouter!;
          } else {
            router = _splashRouter ??= GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Restaurant',
                    appId: 'restaurant',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Restaurant',
                    appId: 'restaurant',
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
            title: 'GrowERP Restaurant',
            router: router,
            extraDelegates: delegates,
            extraBlocProviders: getRestaurantAppBlocProviders(
              widget.restClient,
              widget.applicationId,
            ),
            widgetRegistrations: restaurantWidgetRegistrations,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = const [
  UserCompanyLocalizations.delegate,
  PosLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
];

List<BlocProvider> getRestaurantAppBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getPosBlocProviders(restClient),
    ...getCatalogBlocProviders(restClient, applicationId),
    ...getInventoryBlocProviders(restClient, applicationId),
    ...getOrderAccountingBlocProviders(restClient, applicationId),
  ];
}

/// Widget registrations for all packages used by the Restaurant app.
List<Map<String, GrowerpWidgetBuilder>> restaurantWidgetRegistrations = [
  getUserCompanyWidgets(),
  getPosWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getOrderAccountingWidgets(),
  // App-specific widgets
  {'AboutForm': (args) => const AboutForm()},
];
