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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_options.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'router.dart' as router;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  // can change backend url by pressing long the title on the home screen.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String ip = prefs.getString('ip') ?? '';
  String chat = prefs.getString('chat') ?? '';
  String singleCompany = prefs.getString('companyPartyId') ?? '';
  if (ip.isNotEmpty) {
    late http.Response response;
    try {
      response = await http.get(Uri.parse('${ip}rest/s1/growerp/Ping'));
      if (response.statusCode == 200) {
        GlobalConfiguration().updateValue('databaseUrl', ip);
        GlobalConfiguration().updateValue('chatUrl', chat);
        GlobalConfiguration().updateValue('singleCompany', singleCompany);
        print('=== New ip: $ip , chat: $chat company: $singleCompany Updated!');
      }
    } catch (error) {
      print('===$ip does not respond...not updating databaseUrl: $error');
    }
  }

  await Hive.initFlutter();

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsServer chatServer = WsServer('chat');
  WsServer notificationServer = WsServer('notws');
  String classificationId = GlobalConfiguration().get("classificationId");

  Bloc.observer = AppBlocObserver();
  runApp(TopApp(
    restClient: restClient,
    classificationId: classificationId,
    chatServer: chatServer,
    notificationServer: notificationServer,
    title: 'GrowERP Freelance.',
    router: router.generateRoute,
    menuOptions: menuOptions,
    extraDelegates: const [
      UserCompanyLocalizations.delegate,
      CatalogLocalizations.delegate,
      InventoryLocalizations.delegate,
      OrderAccountingLocalizations.delegate,
      WebsiteLocalizations.delegate,
      MarketingLocalizations.delegate,
      InventoryLocalizations.delegate,
    ],
    extraBlocProviders: [
      ...getUserCompanyBlocProviders(restClient, classificationId),
      ...getCatalogBlocProviders(restClient, classificationId),
      ...getOrderAccountingBlocProviders(restClient, classificationId),
      ...getMarketingBlocProviders(restClient),
      ...getWebsiteBlocProviders(restClient),
    ],
  ));
}
