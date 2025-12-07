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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'widget_registry.dart';
import 'views/freelance_db_form.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  // check if there is override for the production(now test) backend url
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
      try {
        company = await restClient.getCompanyFromHost(hostName);
      } on DioException catch (e) {
        debugPrint("getting hostname error: ${await getDioError(e)}");
      }
      if (company?.partyId == null) company = null;
    }
  }

  runApp(
    FreelanceApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
    ),
  );
}

class FreelanceApp extends StatefulWidget {
  const FreelanceApp({
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
  State<FreelanceApp> createState() => _FreelanceAppState();
}

class _FreelanceAppState extends State<FreelanceApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    // Initialize MenuConfigBloc with AppID 'freelance'
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'freelance');
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
            // Configuration loaded, build dynamic router using shared component
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                mainConfigId: 'FREELANCE_DEFAULT',
                accountingRootOptionId: 'FREELANCE_ACCOUNTING',
                dashboardBuilder: () => const FreelanceDbForm(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Freelance',
              ),
              rootNavigatorKey: GlobalKey<NavigatorState>(),
            );
          } else {
            // Loading or error, show splash screen using shared component
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Freelance',
                    appId: 'freelance',
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
            title: 'GrowERP Freelance.',
            router: router,
            extraDelegates: const [
              UserCompanyLocalizations.delegate,
              CatalogLocalizations.delegate,
              InventoryLocalizations.delegate,
              OrderAccountingLocalizations.delegate,
              WebsiteLocalizations.delegate,
              SalesLocalizations.delegate,
              InventoryLocalizations.delegate,
              ActivityLocalizations.delegate,
            ],
            extraBlocProviders: [
              ...getUserCompanyBlocProviders(
                widget.restClient,
                widget.classificationId,
              ),
              ...getCatalogBlocProviders(
                widget.restClient,
                widget.classificationId,
              ),
              ...getOrderAccountingBlocProviders(
                widget.restClient,
                widget.classificationId,
              ),
              ...getSalesBlocProviders(widget.restClient),
              ...getWebsiteBlocProviders(widget.restClient),
              ...getMarketingBlocProviders(widget.restClient),
              ...getOutreachBlocProviders(widget.restClient),
            ],
          );
        },
      ),
    );
  }
}
