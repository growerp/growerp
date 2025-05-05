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

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'menu_options.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router.dart' as router;
import 'package:http/http.dart' as http;
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
  late http.Response response;
  try {
    late String backendBaseUrl, backendUrl, databaseUrl, chatUrl, secure;
    if (kDebugMode) {
      backendBaseUrl = 'http://localhost:8080';
      databaseUrl = 'databaseUrlDebug';
      chatUrl = 'chatUrlDebug';
      secure = '';
    } else {
      // now at 'org' = test but when in production should be 'com'
      backendBaseUrl = 'https://backend.growerp.org';
      databaseUrl = 'databaseUrl';
      chatUrl = 'chatUrl';
      secure = 's';
    }
    backendUrl = '$backendBaseUrl/rest/s1/growerp/100/BackendUrl?version='
        '${packageInfo.version}&applicationId=$classificationId';
    response = await http.get(Uri.parse(backendUrl));

    String? appBackendUrl = jsonDecode(response.body)['backendUrl'];
    debugPrint(
        "===get backend url: $appBackendUrl resp: ${response.statusCode}");
    if (response.statusCode == 200 && appBackendUrl != null) {
      GlobalConfiguration().updateValue(databaseUrl,
          "http$secure://${jsonDecode(response.body)['backendUrl']}");
      GlobalConfiguration().updateValue(
          chatUrl, "ws$secure://${jsonDecode(response.body)['backendUrl']}");
    }
  } catch (error) {
    debugPrint('===get backend url does not respond...could not find: $error');
  }

  await Hive.initFlutter();

  Map<String, Widget> screens = orderAccountingScreens;

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

  runApp(TopApp(
    restClient: restClient,
    classificationId: classificationId,
    chatClient: chatClient,
    notificationClient: notificationClient,
    title: 'GrowERP administrator.',
    router: router.generateRoute,
    menuOptions: menuOptions,
    extraDelegates: delegates,
    extraBlocProviders: getAdminBlocProviders(restClient, classificationId),
    screens: screens,
    company: company,
  ));
}

List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  MarketingLocalizations.delegate,
  InventoryLocalizations.delegate,
];

List<BlocProvider> getAdminBlocProviders(restClient, classificationId) {
  return [
    ...getInventoryBlocProviders(restClient, classificationId),
    ...getUserCompanyBlocProviders(restClient, classificationId),
    ...getCatalogBlocProviders(restClient, classificationId),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
    ...getMarketingBlocProviders(restClient),
    ...getWebsiteBlocProviders(restClient),
  ];
}
