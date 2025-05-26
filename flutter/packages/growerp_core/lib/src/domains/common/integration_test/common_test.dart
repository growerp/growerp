/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:universal_io/io.dart';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' as found;

import '../../../../growerp_core.dart';
import '../../../../test_data.dart';

class CommonTest {
  static Future<void> takeScreenShot(
      {binding, tester, String? screenShotName}) async {
    if (found.kIsWeb) {
      await binding.takeScreenshot(screenShotName);
      await tester.pumpAndSettle();
      return;
    } else if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot(screenShotName);
    await tester.pumpAndSettle();
  }

  static const int waitTime = 2;

  static Future<void> startTestApp(
      WidgetTester tester,
      Route<dynamic> Function(RouteSettings) router,
      List<MenuOption> menuOptions,
      List<LocalizationsDelegate> extraDelegates,
      {List<BlocProvider>? blocProviders,
      required RestClient restClient,
      bool clear = false,
      String title = "Growerp testing...",
      String classificationId = 'AppAdmin'}) async {
    int seq = Random.secure().nextInt(1024);
    SaveTest test = await PersistFunctions.getTest();
    if (clear == true) {
      await PersistFunctions.persistTest(SaveTest(sequence: seq));
    } else {
      await PersistFunctions.persistTest(test.copyWith(sequence: seq));
    }

    Bloc.observer = AppBlocObserver();
    runApp(TopApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: WsClient('chat'),
      notificationClient: WsClient('notws'),
      router: router,
      title: title,
      menuOptions: menuOptions,
      extraDelegates: extraDelegates,
      extraBlocProviders: blocProviders ?? [],
    ));
    await tester.pump(const Duration());
    await tester.pumpAndSettle(const Duration(seconds: waitTime));
  }

  static Future<void> createCompanyAndAdmin(WidgetTester tester,
      {bool demoData = false, Map testData = const {}}) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence + 1;
    if (test.admin != null) return; // company already created
    // check if email address already exist
    final restClient = RestClient(await buildDioClient(overrideUrl: null));
    var exist = true;
    var times = 0;
    while (exist) {
      try {
        final Map result = await restClient.checkEmail(
            email: admin.email!.replaceFirst('XXX', '${++seq}'));
        exist = result['ok'];
        expect(times++, lessThan(20),
            reason: "Could not find free email address");
      } on DioException catch (e) {
        debugPrint("error checking email: ${await getDioError(e)}");
        expect(true, false, reason: "=============backend error =============");
      }
    }
    // check if logged in, if yes logout first
    await logout(tester);
    // create admin
    await tapByKey(tester, 'newUserButton');
    await enterText(tester, 'firstName', admin.firstName!);
    await enterText(tester, 'lastName', admin.lastName!);
    var email = admin.email!.replaceFirst('XXX', '$seq');
    await enterText(tester, 'email', email);
    await tapByKey(tester, 'newUserButton', seconds: waitTime);
    // start with clean saveTest
    await waitForSnackbarToGo(tester);

    await PersistFunctions.persistTest(SaveTest(
      sequence: ++seq,
      nowDate: DateTime.now(), // used in rental
      admin: admin.copyWith(email: email, loginName: email),
    ));
    await login(tester, testData: testData, demoData: demoData);
  }

  static Future<void> login(WidgetTester tester,
      {String? username,
      String? password,
      bool demoData = false,
      int days = 0,
      Map testData = const {}}) async {
    CustomizableDateTime.customTime = DateTime.now().add(Duration(days: days));
    if (find
        .byKey(const Key('HomeFormAuth'))
        .toString()
        .startsWith('Found 0 widgets with key')) {
      SaveTest test = await PersistFunctions.getTest();
      await pressLoginWithExistingId(tester);
      await enterText(tester, 'username', username ?? test.admin!.email!);
      await enterText(tester, 'password', password ?? 'qqqqqq9!');
      await pressLogin(tester);
      await waitForSnackbarToGo(tester);
      if (find
          .byKey(const Key('moreInfo'))
          .toString()
          .startsWith('Found 1 widget')) {
        String companyName = '${initialCompany.name!} ${test.sequence}';
        await enterText(tester, 'companyName', companyName);
        await enterDropDown(
            tester, 'currency', initialCompany.currency!.description!);
        if (demoData == false) {
          await tapByKey(tester, 'demoData');
        } // no demo data
        await tapByKey(tester, 'continue', seconds: waitTime);
        await waitForSnackbarToGo(tester);
        await PersistFunctions.persistTest(test.copyWith(
            company:
                Company(name: companyName, currency: initialCompany.currency),
            sequence: test.sequence + 1,
            nowDate: DateTime.now())); // used in rental
      }
    }

    SaveTest test = await PersistFunctions.getTest();
    String apiKey = getTextField('apiKey');
    String moquiSessionToken = getTextField('moquiSessionToken');
    await GlobalConfiguration()
        .add({"apiKey": apiKey, "moquiSessionToken": moquiSessionToken});
    int seq = test.sequence;
    if (!test.testDataLoaded && testData.isNotEmpty) {
      final restClient = RestClient(await buildDioClient());
      // replace XXX strings
      Map<String, dynamic> parsed = {};
      testData.forEach((k, v) {
        List newList = [];
        v.forEach((item) {
          if (item is Company || item is User) {
            if (item.email != null) {
              item = item.copyWith(
                  email: item.email!.replaceFirst('XXX', '${seq++}'));
            }
          }
          if (item is User) {
            if (item.loginName != null) {
              item = item.copyWith(
                  loginName: item.loginName!.replaceFirst('XXX', '${seq++}'));
            }
          }
          newList.add(item);
        });
        parsed[k] = newList;
      });
      await restClient.uploadEntities(
          entities: parsed, classificationId: 'AppAdmin');
    }
    await PersistFunctions.persistTest(
        test.copyWith(sequence: seq, testDataLoaded: true));
  }

  static checkCompanyAndAdmin(
    WidgetTester tester,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    // appbar
    expect(getTextField('appBarAvatarText'), equals(test.company!.name![0]));
    expect(getTextField('appBarCompanyName'), equals(test.company!.name));
    // company
    expect(getTextField('dbCompanyTitle'), equals("Organization"));
    expect(getTextField('dbCompanySubTitle0'), equals(test.company!.name));
    //  expect(getTextField('dbCompanySubTitle1'),
    //      equals("Email: ${test.company!.email}"));
    expect(getTextField('dbCompanySubTitle2'),
        equals("Currency: ${test.company!.currency!.description}"));
    expect(getTextField('dbCompanySubTitle3'),
        equals("Employees: ${test.company!.employees.length + 1}"));
    // User
    expect(getTextField('dbUserTitle'), equals("Logged in User"));
    expect(getTextField('dbUserSubTitle0'),
        equals("${test.admin!.firstName} ${test.admin!.lastName}"));
    expect(
        getTextField('dbUserSubTitle1'), equals("Email: ${test.admin!.email}"));
    expect(getTextField('dbUserSubTitle2'), equals("Login name:"));
    expect(getTextField('dbUserSubTitle3'), equals(" ${test.admin!.email}"));
    expect(getTextField('dbUserSubTitle4'),
        equals("Security Group: ${test.admin!.userGroup!.name}"));
  }

  static takeScreenshot(WidgetTester tester,
      IntegrationTestWidgetsFlutterBinding binding, String name) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot(name);
  }

  static Future<void> selectOption(
      WidgetTester tester, String option, String formName,
      [String? tapNumber]) async {
    if (isPhone()) {
      expect(find.byTooltip('Open navigation menu'), findsOneWidget,
          reason: "could not find tooltip: 'Open navigation menu' to tap on");
      await tester.tap(
        find.byTooltip('Open navigation menu'),
      );
      await tester.pump(const Duration(seconds: waitTime));
    }
    if (!option.startsWith('tap')) {
      if (option.startsWith('db')) {
        // convert old mainscrean tapping to drawer on mobile
        option = "/${option.substring(2).toLowerCase()}";
      } else if (!option.startsWith('/')) {
        option = "/$option";
      }
      option = "tap$option";
    }
    await tapByKey(tester, option, seconds: waitTime);
    if (tapNumber != null) {
      if (isPhone()) {
        await tapByTooltip(tester, tapNumber);
      } else {
        await tapByKey(tester, "tap$formName");
      }
      await tester.pumpAndSettle(const Duration(seconds: waitTime));
    }
    await checkWidgetKey(tester, formName);
  }

  static Future<void> gotoMainMenu(WidgetTester tester) async {
    await selectMainMenu(tester, "tap/");
  }

  static Future<void> selectMainCompany(WidgetTester tester) async {
    await tapByKey(tester, 'tapCompany');
    await checkWidgetKey(tester, 'CompanyDialogOrgInternal');
  }

  static Future<void> doNewSearch(WidgetTester tester,
      {required String searchString, int? seconds}) async {
    seconds ??= waitTime;
    await tapByKey(tester, 'search');
    await enterText(tester, 'searchField', searchString);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: waitTime));
    await tapByText(tester, searchString);
    await tester.pumpAndSettle(const Duration(seconds: waitTime));
  }

  static Future<void> doSearch(WidgetTester tester,
      {required String searchString, int? seconds}) async {
    seconds ??= waitTime;
    if (tester.any(find.byKey(const Key('searchButton'))) == false) {
      await tapByKey(tester, 'search');
    }
    await enterText(tester, 'searchField', searchString);
    await tapByKey(tester, 'searchButton', seconds: seconds);
  }

  static Future<void> closeSearch(WidgetTester tester) async {
    if (tester.any(find.byKey(const Key('searchButton'))) == true) {
      await tapByKey(tester, 'search');
    } // cancel search
  }

  static Future<void> pressLoginWithExistingId(WidgetTester tester) async {
    await tapByKey(tester, 'loginButton', seconds: 1);
  }

  static Future<void> pressLogin(WidgetTester tester) async {
    await tapByKey(tester, 'login', seconds: waitTime);
  }

  static Future<void> logout(WidgetTester tester) async {
    if (hasKey('HomeFormUnAuth')) return; // already logged out
    await gotoMainMenu(tester);
    if (hasKey('HomeFormAuth')) {
      debugPrint("Dashboard logged in , needs to logout");
      await tapByKey(tester, 'logoutButton');
      await tester.pump(const Duration(seconds: waitTime));
      expect(find.byKey(const Key('HomeFormUnAuth')), findsOneWidget);
      await waitForSnackbarToGo(tester);
    }
  }

  // low level ------------------------------------------------------------

  static Future<bool> waitForKey(WidgetTester tester, String keyName) async {
    int times = 0;
    bool found = false;
    while (times++ < 10 && found == false) {
      found = tester.any(find.byKey(Key(keyName), skipOffstage: true));
      await tester.pump(const Duration(milliseconds: 500));
    }
    //expect(found, true,
    //    reason: 'key $keyName not found even after 6 seconds wait!');
    return found;
  }

  static Future<bool> waitForSnackbarToGo(WidgetTester tester) async {
    int times = 0;
    bool found = true;
    await tester.pump();
    if (hasKey('dismiss')) await tapByText(tester, 'dismiss');
    await tester.pumpAndSettle();
    while (times++ < 10 && found == true) {
      found = tester.any(find.byType(SnackBar));
      await tester.pump(const Duration(milliseconds: 500));
    }
    return found;
  }

  static Future<void> checkWidgetKey(WidgetTester tester, String widgetKey,
      [int count = 1]) async {
    expect(find.byKey(Key(widgetKey)), findsNWidgets(count),
        reason: "looking for widget key: $widgetKey failed");
  }

  static Future<bool> doesExistKey(WidgetTester tester, String widgetKey,
      [int count = 1]) async {
    if (find
        .byKey(Key(widgetKey))
        .toString()
        .startsWith('Found 0 widgets with key')) {
      return false;
    }
    return true;
  }

  /// check if a particular text can be found on the page.
  static Future<void> checkText(WidgetTester tester, String text) async {
    expect(find.textContaining(RegExp(text, caseSensitive: false)).last,
        findsOneWidget);
  }

  /// [lowLevel]
  static Future<void> drag(WidgetTester tester,
      {int seconds = 1, String listViewName = 'listView'}) async {
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(Key(listViewName)).last, const Offset(0, -300));
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> dragNew(WidgetTester tester,
      {String key = 'listView'}) async {
    await tester.pumpAndSettle();
    await tester.fling(find.byKey(Key(key)).last, const Offset(0, -300), 2000);
    await tester.pumpAndSettle();
  }

  static Future<void> dragUntil(WidgetTester tester,
      {String listViewName = 'listView', required String key}) async {
    int times = 0;
    bool found = false;
    await tester.pumpAndSettle();
    do {
      await tester.drag(
          find.byKey(Key(listViewName)).last, const Offset(0, -200));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      found = tester.any(find.byKey(Key(key)));
    } while (times++ < 10 && found == false);
  }

  /// [lowLevel]
  static Future<void> refresh(WidgetTester tester,
      {int seconds = waitTime, String listViewName = 'listView'}) async {
    await tester.drag(find.byKey(Key(listViewName)).last, const Offset(0, 400));
    await tester.pump(Duration(seconds: seconds));
    await tester.pumpAndSettle();
  }

  static Future<void> enterText(
      WidgetTester tester, String key, String value) async {
    await tester.pump();
    await tester.enterText(find.byKey(Key(key)), value);
    await tester.pump();
  }

  static Future<void> enterDropDownSearch(
      WidgetTester tester, String key, String value,
      {int seconds = 1, check = false}) async {
    await tapByKey(tester, key); // open search dropdown
    await tester.enterText(find.byType(TextField).last, value);
    await tester.pumpAndSettle(
        const Duration(seconds: waitTime)); // wait for search result
    if (check) {
      await tapByType(tester, Checkbox);
    } else {
      expect(find.textContaining(value).last, findsOneWidget,
          reason: "could not find text in dropdown: $value");
      await tester.tap(find.textContaining(value).last);
    }
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> enterDropDown(
      WidgetTester tester, String key, String value,
      {int seconds = 1}) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle(Duration(seconds: seconds));
    if (value.isEmpty) {
      await tester.tap(find.text(value).last);
    } else {
      await tester.tap(find.textContaining(value).last);
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  static String getDropdown(String key,
      {String classificationId = 'AppAdmin'}) {
    DropdownButtonFormField tff = find
        .byKey(Key(key))
        .last
        .evaluate()
        .single
        .widget as DropdownButtonFormField;
    if (tff.initialValue is Currency) return tff.initialValue.description;
    if (tff.initialValue is UserGroup) return tff.initialValue.toString();
    if (tff.initialValue is RequestType) return tff.initialValue.value;
    if (tff.initialValue is Role) return tff.initialValue.value;
    if (tff.initialValue is FinDocStatusVal) {
      return classificationId == 'AppHotel'
          ? tff.initialValue.hotel as String
          : tff.initialValue.name as String;
    }
    return tff.initialValue;
  }

  static String getDropdownSearch(String key) {
    DropdownSearch tff =
        find.byKey(Key(key)).evaluate().single.widget as DropdownSearch;
    if (tff.selectedItem is Country) return tff.selectedItem.name;
    if (tff.selectedItem is Category) return tff.selectedItem.categoryName;
    if (tff.selectedItem is Product) return tff.selectedItem.productName;
    if (tff.selectedItem is User) return tff.selectedItem.company.name;
    if (tff.selectedItem is Company) return tff.selectedItem.name;
    if (tff.selectedItem is CompanyUser) return tff.selectedItem.name;
    if (tff.selectedItem is AccountClass) {
      return "${tff.selectedItem.topDescription}-${tff.selectedItem.parentDescription}-${tff.selectedItem.description}-${tff.selectedItem.detailDescription}";
    }
    if (tff.selectedItem is AccountType) return tff.selectedItem.description;
    return tff.selectedItem.toString();
  }

  /// get the content of a text field identified by a key
  static String getTextField(String key) {
    Text tf = find.byKey(Key(key)).last.evaluate().single.widget as Text;
    return tf.data!;
  }

  /// get the content of a TextFormField providing the key
  static String getTextFormField(String key) {
    TextFormField tff =
        find.byKey(Key(key)).evaluate().single.widget as TextFormField;
    return tff.controller!.text;
  }

  static bool getCheckbox(String key) {
    Checkbox tff = find.byKey(Key(key)).evaluate().single.widget as Checkbox;
    return tff.value ?? false;
  }

  static bool getRadio(String key) {
    Radio tff = find.byKey(Key(key)).evaluate().single.widget as Radio;
    return tff.groupValue;
  }

  static bool getCheckboxListTile(String text) {
    CheckboxListTile tff =
        find.text(text).evaluate().single.widget as CheckboxListTile;
    return tff.value ?? false;
  }

  static bool isPhone() {
    try {
      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool hasKey(String key) {
    if (find
        .byKey(Key(key))
        .toString()
        .startsWith('Found 0 widgets with key')) {
      return false;
    }
    return true;
  }

  static Future<void> selectMainMenu(
      WidgetTester tester, String menuOption) async {
    if (hasKey('cancel')) {
      // company or user detail menu open?
      await tester.tap(find.byKey(const Key('cancel')).last);
      await tester.pump();
    }
    if (!hasKey('HomeFormAuth')) {
      if (isPhone()) {
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: waitTime));
      }
      await tapByKey(tester, menuOption);
    }
  }

  static Future<void> tapByKey(WidgetTester tester, String key,
      {int seconds = 1}) async {
    await tester.tap(find.byKey(Key(key)).last);
    await tester.pump();
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> tapByWidget(WidgetTester tester, Widget widget,
      {int seconds = 1}) async {
    await tester.tap(find.byWidget(widget).first);
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> tapByType(WidgetTester tester, Type type,
      {int seconds = 1}) async {
    await tester.tap(find.byType(type).first);
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> tapByText(WidgetTester tester, String text,
      {int seconds = 1}) async {
    await tester
        .tap(find.textContaining(RegExp(text, caseSensitive: false)).last);
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> tapByTooltip(WidgetTester tester, String text,
      {int seconds = 1}) async {
    await tester.tap(find.byTooltip(text));
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> selectDropDown(
      WidgetTester tester, String key, String value,
      {seconds = 1}) async {
    await tapByKey(tester, key, seconds: seconds);
    await tapByText(tester, value);
  }

  static String getRandom() {
    Text tff = find
        .byKey(const Key('appBarCompanyName'))
        .evaluate()
        .single
        .widget as Text;
    return tff.data!.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static int getWidgetCountByKey(WidgetTester tester, String key) {
    var finder = find.byKey(Key(key));
    return tester.widgetList(finder).length;
  }

  static void mockPackageInfo() {
    const channel = MethodChannel('plugins.flutter.io/package_info');

    handler(MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'myapp',
          'packageName': 'com.mycompany.myapp',
          'version': '0.0.1',
          'buildNumber': '1'
        };
      }
      return null;
    }

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  static void mockImagePicker() {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/image_picker');

    handler(MethodCall methodCall) async {
      ByteData data = await rootBundle.load('assets/images/crm.png');
      Uint8List bytes = data.buffer.asUint8List();
      Directory tempDir = await getTemporaryDirectory();
      File file = await File(
        '${tempDir.path}/tmp.tmp',
      ).writeAsBytes(bytes);
      debugPrint('=========${file.path}');
      return [
        // file.path;
        {
          'name': "Icon.png",
          'path': file.path,
          'bytes': bytes,
          'size': bytes.lengthInBytes,
        }
      ];
    }

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  static void mockUrlLauncher() {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/url_launcher');

    handler(MethodCall methodCall) async {
      debugPrint("=========$methodCall");
    }

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  static Future<String?> getRelatedFindoc(
      WidgetTester tester, FinDocType type) async {
    if (tester.any(find.byKey(Key("rel$type"))) == false) return null;
    await tapByKey(tester, "rel$type");
    String id = getTextField('topHeader').split('#')[1];
    await tapByKey(tester, 'cancel');
    return id;
  }
}
