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

// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:star_menu/star_menu.dart';
import 'package:workflow/forms/element_settings_menu.dart';
import 'package:workflow/forms/text_menu.dart';
import 'menu_options.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router.dart' as router;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as path;

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
        debugPrint(
            '=== New ip: $ip , chat: $chat company: $singleCompany Updated!');
      }
    } catch (error) {
      debugPrint('===$ip does not respond...not updating databaseUrl: $error');
    }
  }

  await Hive.initFlutter();

  Bloc.observer = AppBlocObserver();
  runApp(TopApp(
    restClient: RestClient(await buildDioClient()),
    classificationId: 'AppAdmin',
    chatServer: ChatServer(),
    title: 'GrowERP Workflow Management.',
    router: router.generateRoute,
    menuOptions: menuOptions,
    extraDelegates: extraDelegates,
  ));
}

List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  MarketingLocalizations.delegate,
  InventoryLocalizations.delegate,
];

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Dashboard dashboard = Dashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.black12,
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: FlowChart(
          dashboard: dashboard,
          onDashboardTapped: ((context, position) {
            debugPrint('Dashboard tapped $position');
            _displayDashboardMenu(context, position);
          }),
          onDashboardSecondaryTapped: (context, position) {
            debugPrint('Dashboard right clicked $position');
            _displayDashboardMenu(context, position);
          },
          onDashboardLongtTapped: ((context, position) {
            debugPrint('Dashboard long tapped $position');
          }),
          onDashboardSecondaryLongTapped: ((context, position) {
            debugPrint(
                'Dashboard long tapped with mouse right click $position');
          }),
          onElementLongPressed: (context, position, element) {
            debugPrint('Element with "${element.text}" text '
                'long pressed');
          },
          onElementSecondaryLongTapped: (context, position, element) {
            debugPrint('Element with "${element.text}" text '
                'long tapped with mouse right click');
          },
          onElementPressed: (context, position, element) {
            debugPrint('Element with "${element.text}" text pressed');
            _displayElementMenu(context, position, element);
          },
          onElementSecondaryTapped: (context, position, element) {
            debugPrint('Element with "${element.text}" text pressed');
            _displayElementMenu(context, position, element);
          },
          onHandlerPressed: (context, position, handler, element) {
            debugPrint('handler pressed: position $position '
                'handler $handler" of element $element');
            _displayHandlerMenu(position, handler, element);
          },
          onHandlerLongPressed: (context, position, handler, element) {
            debugPrint('handler long pressed: position $position '
                'handler $handler" of element $element');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: dashboard.recenter,
          child: const Icon(Icons.center_focus_strong)),
    );
  }

  //*********************
  //* POPUP MENUS
  //*********************

  /// Display a drop down menu when tapping on a handler
  _displayHandlerMenu(
    Offset position,
    Handler handler,
    FlowElement element,
  ) {
    StarMenuOverlay.displayStarMenu(
      context,
      StarMenu(
        params: StarMenuParameters(
          shape: MenuShape.linear,
          openDurationMs: 60,
          linearShapeParams: const LinearShapeParams(
            angle: 270,
            space: 10,
          ),
          onHoverScale: 1.1,
          useTouchAsCenter: true,
          centerOffset: position -
              Offset(
                dashboard.dashboardSize.width / 2,
                dashboard.dashboardSize.height / 2,
              ),
        ),
        onItemTapped: (index, controller) => controller.closeMenu!(),
        items: [
          FloatingActionButton(
            child: const Icon(Icons.delete),
            onPressed: () =>
                dashboard.removeElementConnection(element, handler),
          )
        ],
        parentContext: context,
      ),
    );
  }

  /// Display a drop down menu when tapping on an element
  _displayElementMenu(
    BuildContext context,
    Offset position,
    FlowElement element,
  ) {
    StarMenuOverlay.displayStarMenu(
      context,
      StarMenu(
        params: StarMenuParameters(
          shape: MenuShape.linear,
          openDurationMs: 60,
          linearShapeParams: const LinearShapeParams(
            angle: 270,
            alignment: LinearAlignment.left,
            space: 10,
          ),
          onHoverScale: 1.1,
          centerOffset: position - const Offset(50, 0),
          backgroundParams: const BackgroundParams(
            backgroundColor: Colors.transparent,
          ),
          boundaryBackground: BoundaryBackground(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
              boxShadow: kElevationToShadow[6],
            ),
          ),
        ),
        onItemTapped: (index, controller) {
          if (!(index == 5 || index == 2)) {
            controller.closeMenu!();
          }
        },
        items: [
          Text(
            element.text,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          InkWell(
            onTap: () => dashboard.removeElement(element),
            child: const Text('Delete'),
          ),
          TextMenu(element: element),
          InkWell(
            onTap: () {
              dashboard.removeElementConnections(element);
            },
            child: const Text('Remove all connections'),
          ),
          InkWell(
            onTap: () {
              dashboard.setElementResizable(element, true);
            },
            child: const Text('Resize'),
          ),
          ElementSettingsMenu(
            element: element,
          ),
        ],
        parentContext: context,
      ),
    );
  }

  /// Display a linear menu for the dashboard
  /// with menu entries built with [menuEntries]
  _displayDashboardMenu(BuildContext context, Offset position) {
    StarMenuOverlay.displayStarMenu(
      context,
      StarMenu(
        params: StarMenuParameters(
          shape: MenuShape.linear,
          openDurationMs: 60,
          linearShapeParams: const LinearShapeParams(
            angle: 270,
            alignment: LinearAlignment.left,
            space: 10,
          ),
          // calculate the offset from the dashboard center
          centerOffset: position -
              Offset(
                dashboard.dashboardSize.width / 2,
                dashboard.dashboardSize.height / 2,
              ),
        ),
        onItemTapped: (index, controller) => controller.closeMenu!(),
        parentContext: context,
        items: [
          ActionChip(
              label: const Text('Add diamond'),
              onPressed: () {
                dashboard.addElement(FlowElement(
                    position: position - const Offset(40, 40),
                    size: const Size(80, 80),
                    text: '${dashboard.elements.length}',
                    kind: ElementKind.diamond,
                    handlers: [
                      Handler.bottomCenter,
                      Handler.topCenter,
                      Handler.leftCenter,
                      Handler.rightCenter,
                    ]));
              }),
          ActionChip(
              label: const Text('Add rect'),
              onPressed: () {
                dashboard.addElement(FlowElement(
                    position: position - const Offset(50, 25),
                    size: const Size(100, 50),
                    text: '${dashboard.elements.length}',
                    kind: ElementKind.rectangle,
                    handlers: [
                      Handler.bottomCenter,
                      Handler.topCenter,
                      Handler.leftCenter,
                      Handler.rightCenter,
                    ]));
              }),
          ActionChip(
              label: const Text('Add oval'),
              onPressed: () {
                dashboard.addElement(FlowElement(
                    position: position - const Offset(50, 25),
                    size: const Size(100, 50),
                    text: '${dashboard.elements.length}',
                    kind: ElementKind.oval,
                    handlers: [
                      Handler.bottomCenter,
                      Handler.topCenter,
                      Handler.leftCenter,
                      Handler.rightCenter,
                    ]));
              }),
          ActionChip(
              label: const Text('Add parallelogram'),
              onPressed: () {
                dashboard.addElement(FlowElement(
                    position: position - const Offset(50, 25),
                    size: const Size(100, 50),
                    text: '${dashboard.elements.length}',
                    kind: ElementKind.parallelogram,
                    handlers: [
                      Handler.bottomCenter,
                      Handler.topCenter,
                    ]));
              }),
          ActionChip(
              label: const Text('Add storage'),
              onPressed: () {
                dashboard.addElement(FlowElement(
                    position: position - const Offset(50, 25),
                    size: const Size(100, 150),
                    text: '${dashboard.elements.length}',
                    kind: ElementKind.storage,
                    handlers: [
                      Handler.bottomCenter,
                      Handler.leftCenter,
                      Handler.rightCenter,
                    ]));
              }),
          ActionChip(
              label: const Text('Remove all'),
              onPressed: () {
                dashboard.removeAllElements();
              }),
          ActionChip(
              label: const Text('SAVE dashboard'),
              onPressed: () async {
                Directory appDocDir =
                    await path.getApplicationDocumentsDirectory();
                dashboard.saveDashboard('${appDocDir.path}/FLOWCHART.json');
              }),
          ActionChip(
              label: const Text('LOAD dashboard'),
              onPressed: () async {
                Directory appDocDir =
                    await path.getApplicationDocumentsDirectory();
                dashboard.loadDashboard('${appDocDir.path}/FLOWCHART.json');
              }),
        ],
      ),
    );
  }
}
