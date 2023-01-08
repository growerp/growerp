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

import 'dart:io';
import 'dart:math';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import '../../../api_repository.dart';
import '../../../services/chat_server.dart';
import '../../common/functions/functions.dart';
import '../../domains.dart';
import '../../../extensions.dart';
import '../widgets/top_app.dart';

class CommonTest {
  String classificationId = GlobalConfiguration().get("classificationId");

  static Future<void> startApp(WidgetTester tester, Widget TopApp,
      {bool clear = false}) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = Random.secure().nextInt(1024) + test.sequence;
    print("====startapp seq: $seq");
    if (clear == true) {
      await PersistFunctions.persistTest(SaveTest(sequence: seq));
    } else {
      await PersistFunctions.persistTest(test.copyWith(sequence: seq));
    }
    await BlocOverrides.runZoned(
        () async => await tester.pumpWidget(Phoenix(child: TopApp)),
        blocObserver: AppBlocObserver());
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  static Future<void> startTestApp(
      WidgetTester tester,
      Route<dynamic> Function(RouteSettings) router,
      List<MenuOption> menuOptions,
      {bool clear = false}) async {
    int seq = Random.secure().nextInt(1024);
    SaveTest test = await PersistFunctions.getTest();
    print("====startapp seq: $seq");
    if (clear == true) {
      await PersistFunctions.persistTest(SaveTest(sequence: seq));
    } else {
      await PersistFunctions.persistTest(test.copyWith(sequence: seq));
    }
    Bloc.observer = AppBlocObserver();
    runApp(TopApp(
        dbServer: APIRepository(),
        chatServer: ChatServer(),
        router: router,
        menuOptions: menuOptions));
    await tester.pumpAndSettle(Duration(seconds: 5));
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
    if (!option.startsWith('accnt')) await gotoMainMenu(tester);
    await tapByKey(tester, option, seconds: 3);
    if (tapNumber != null) {
      if (isPhone())
        await tester.tap(find.byTooltip(tapNumber));
      else
        await tester.tap(find.byKey(Key("tap$formName")));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    await checkWidgetKey(tester, formName);
  }

  static Future<void> login(WidgetTester tester,
      {String? username, String? password, int days = 0}) async {
    CustomizableDateTime.customTime = DateTime.now().add(Duration(days: days));
    SaveTest test = await PersistFunctions.getTest();
    if ((test.company == null || test.admin == null) &&
        (username == null || password == null)) {
      print("Need company test to be run first");
      return;
    }
    if (find
        .byKey(Key('HomeFormAuth'))
        .toString()
        .startsWith('zero widgets with key')) {
      await pressLoginWithExistingId(tester);
      await enterText(
          tester, 'username', username == null ? test.admin!.email! : username);
      await enterText(
          tester, 'password', password == null ? 'qqqqqq9!' : password);
      await pressLogin(tester);
      await checkText(tester, 'Main'); // dashboard
    }
  }

  static Future<void> gotoMainMenu(WidgetTester tester) async {
    await selectMainMenu(tester, "tap/");
  }

  static Future<void> doSearch(WidgetTester tester,
      {required String searchString, int seconds = 5}) async {
    if (tester.any(find.byKey(Key('searchButton'))) == false)
      await tapByKey(tester, 'search');
    await enterText(tester, 'searchField', searchString);
    await tapByKey(tester, 'searchButton', seconds: seconds);
  }

  static Future<void> closeSearch(WidgetTester tester) async {
    if (tester.any(find.byKey(Key('searchButton'))) == true)
      await tapByKey(tester, 'search'); // cancel search
  }

  static Future<void> pressLoginWithExistingId(WidgetTester tester) async {
    await tapByKey(tester, 'loginButton', seconds: 1);
  }

  static Future<void> pressLogin(WidgetTester tester) async {
    await tapByKey(tester, 'login', seconds: 5);
  }

  static Future<void> logout(WidgetTester tester) async {
    if (hasKey('HomeFormUnAuth')) return; // already logged out
    await gotoMainMenu(tester);
    if (hasKey('HomeFormAuth')) {
      print("Dashboard logged in , needs to logout");
      await tapByKey(tester, 'logoutButton');
      await tester.pump(Duration(seconds: 5));
      expect(find.byKey(Key('HomeFormUnAuth')), findsOneWidget);
    }
  }

  // low level ------------------------------------------------------------

  static Future<bool> waitForKey(WidgetTester tester, String keyName) async {
    int times = 0;
    bool found = false;
    while (times++ < 10 && found == false) {
      found = tester.any(find.byKey(Key(keyName), skipOffstage: true));
      await tester.pump(Duration(milliseconds: 500));
    }
    if (found)
      print("=== waited for key $keyName to show: ${times * 0.5} seconds");
    //expect(found, true,
    //    reason: 'key $keyName not found even after 6 seconds wait!');
    return found;
  }

  static Future<bool> waitForSnackbarToGo(WidgetTester tester) async {
    int times = 0;
    bool found = true;
    while (times++ < 10 && found == true) {
      found = tester.any(find.byType(SnackBar));
      await tester.pump(Duration(milliseconds: 500));
    }
    if (!found)
      print("=== waited for message to disappear: ${times * 0.5} seconds");
//    expect(found, false,
//        reason: 'Snackbar still found, even after 6 seconds wait!');
    return found;
  }

  static Future<void> checkWidgetKey(WidgetTester tester, String widgetKey,
      [int count = 1]) async {
    expect(find.byKey(Key(widgetKey)), findsNWidgets(count));
  }

  static Future<bool> doesExistKey(WidgetTester tester, String widgetKey,
      [int count = 1]) async {
    if (find
        .byKey(Key(widgetKey))
        .toString()
        .startsWith('zero widgets with key')) return false;
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
    await tester.drag(find.byKey(Key(listViewName)).last, Offset(0, -400));
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> dragUntil(WidgetTester tester,
      {String listViewName = 'listView', required String key}) async {
    int times = 0;
    bool found = false;
    do {
      await tester.drag(find.byKey(Key(listViewName)).last, Offset(0, -400));
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      found = tester.any(find.byKey(Key(key)));
    } while (times++ < 10 && found == false);
    print("======dragged $times times");
  }

  /// [lowLevel]
  static Future<void> refresh(WidgetTester tester,
      {int seconds = 5, String listViewName = 'listView'}) async {
    await tester.drag(find.byKey(Key(listViewName)).last, Offset(0, 400));
    await tester.pump(Duration(seconds: seconds));
  }

  static Future<void> enterText(
      WidgetTester tester, String key, String value) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump(Duration(seconds: 1));
    await tester.enterText(find.byKey(Key(key)), value);
    await tester.pump();
  }

  static Future<void> enterDropDownSearch(
      WidgetTester tester, String key, String value,
      {int seconds = 1}) async {
    await tapByKey(tester, key);
    await tester.enterText(find.byType(TextField).last, value);
    await tester.pumpAndSettle(Duration(seconds: 5)); // wait for search result
    await tester
        .tap(find.textContaining(RegExp(value, caseSensitive: false)).last);
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  static Future<void> enterDropDown(
      WidgetTester tester, String key, String value,
      {int seconds = 1}) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle(Duration(seconds: seconds));
    await tester.tap(find.textContaining(value).last);
    await tester.pumpAndSettle(Duration(seconds: 1));
  }

  static String getDropdown(String key) {
    DropdownButtonFormField tff = find.byKey(Key(key)).evaluate().single.widget
        as DropdownButtonFormField;
    if (tff.initialValue is Currency) return tff.initialValue.description;
    if (tff.initialValue is UserGroup) return tff.initialValue.toString();
    return tff.initialValue;
  }

  static String getDropdownSearch(String key) {
    DropdownSearch tff =
        find.byKey(Key(key)).evaluate().single.widget as DropdownSearch;
    if (tff.selectedItem is Country) return tff.selectedItem.name;
    if (tff.selectedItem is Category) return tff.selectedItem.categoryName;
    if (tff.selectedItem is Product) return tff.selectedItem.productName;
    if (tff.selectedItem is User) return tff.selectedItem.companyName;
    return tff.selectedItem.toString();
  }

  /// get the content of a text field identified by a key
  static String getTextField(String key) {
    Text tf = find.byKey(Key(key)).evaluate().single.widget as Text;
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
    if (find.byKey(Key(key)).toString().startsWith('zero widgets with key'))
      return false;
    return true;
  }

  static Future<void> selectMainMenu(
      WidgetTester tester, String menuOption) async {
    if (!hasKey('HomeFormAuth')) {
      if (isPhone()) {
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pump();
        await tester.pumpAndSettle(Duration(seconds: 5));
      }
      await tapByKey(tester, menuOption);
    }
  }

  static Future<void> tapByKey(WidgetTester tester, String key,
      {int seconds = 1}) async {
    await tester.tap(find.byKey(Key(key)).last);
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
      {seconds: 1}) async {
    await tapByKey(tester, key, seconds: seconds);
    await tapByText(tester, value);
  }

  static String getRandom() {
    Text tff =
        find.byKey(Key('appBarCompanyName')).evaluate().single.widget as Text;
    return tff.data!.replaceAll(new RegExp(r'[^0-9]'), '');
  }

  static int getWidgetCountByKey(WidgetTester tester, String key) {
    var finder = find.byKey(Key(key));
    return tester.widgetList(finder).length;
  }

  static Future<void> updateAddress(
      WidgetTester tester, Address address) async {
    await drag(tester);
    await tapByKey(tester, 'address');
    await enterText(tester, 'address1', address.address1!);
    await enterText(tester, 'address2', address.address2!);
    await enterText(tester, 'postalCode', address.postalCode!);
    await enterText(tester, 'city', address.city!);
    await enterText(tester, 'province', address.province!);
    await drag(tester);
    await enterDropDownSearch(tester, 'country', address.country!);
    await drag(tester);
    await tapByKey(tester, 'updateAddress');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkAddress(WidgetTester tester, Address address) async {
    await drag(tester);
    await tapByKey(tester, 'address');
    expect(getTextFormField('address1'), contains(address.address1!));
    expect(getTextFormField('address2'), contains(address.address2!));
    expect(getTextFormField('postalCode'), contains(address.postalCode));
    expect(getTextFormField('city'), contains(address.city!));
    expect(getTextFormField('province'), equals(address.province!));
    expect(getDropdownSearch('country'), equals(address.country));
    await tapByKey(tester, 'cancel');
  }

  static Future<void> updatePaymentMethod(
      WidgetTester tester, PaymentMethod paymentMethod) async {
    await drag(tester);
    await tapByKey(tester, 'paymentMethod');
    await enterDropDown(
        tester, 'cardTypeDropDown', paymentMethod.creditCardType.toString());
    await enterText(
        tester, 'creditCardNumber', paymentMethod.creditCardNumber!);
    await enterText(tester, 'expireMonth', paymentMethod.expireMonth!);
    await enterText(tester, 'expireYear', paymentMethod.expireYear!);
    await tapByKey(tester, 'updatePaymentMethod');
    await CommonTest.waitForKey(tester, 'dismiss');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> checkPaymentMethod(
      WidgetTester tester, PaymentMethod paymentMethod) async {
    int length = paymentMethod.creditCardNumber!.length;
    await drag(tester);
    expect(
        getTextField('paymentMethodLabel'),
        contains(
            paymentMethod.creditCardNumber!.substring(length - 4, length)));
    expect(getTextField('paymentMethodLabel'),
        contains(paymentMethod.expireMonth! + '/'));
    expect(getTextField('paymentMethodLabel'),
        contains(paymentMethod.expireYear!));
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

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  static void mockImage_picker() {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/image_picker');

    _handler(MethodCall methodCall) async {
      ByteData data = await rootBundle.load('assets/images/crm.png');
      Uint8List bytes = data.buffer.asUint8List();
      Directory tempDir = await getTemporaryDirectory();
      File file = await File(
        '${tempDir.path}/tmp.tmp',
      ).writeAsBytes(bytes);
      print('=========' + file.path);
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

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _handler);
  }

  static void mockUrl_launcher() {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/url_launcher');

    _handler(MethodCall methodCall) async {
      print("=========" + methodCall.toString());
    }

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _handler);
  }
}
