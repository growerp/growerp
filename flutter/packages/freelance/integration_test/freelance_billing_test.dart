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

// Freelance time-billing workflow:
// 1. create company + admin, create a client (customer)
// 2. create a task for the client with an hourly rate
// 3. enter hours on the task, approve them
// 4. generate a sales invoice for the client from the approved hours
// 5. generate a purchase (self-billing) invoice for the assistant
// 6. check the hours report shows the hours as invoiced

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_user_company/src/user/integration_test/user_test.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';

const freelanceTestMenuConfig = MenuConfiguration(
  menuConfigurationId: 'FREELANCE_TEST',
  appId: 'freelance',
  name: 'Freelance Test Menu',
  menuItems: [
    MenuItem(
      itemKey: 'FL_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'FreelanceDashboard',
    ),
    MenuItem(
      itemKey: 'FL_TASKS',
      title: 'Tasks',
      route: '/tasks',
      iconName: 'task',
      sequenceNum: 20,
      widgetName: 'ActivityList',
    ),
    MenuItem(
      itemKey: 'FL_HOURS',
      title: 'Hours',
      route: '/hours',
      iconName: 'schedule',
      sequenceNum: 30,
      widgetName: 'TimeEntryReportList',
    ),
    MenuItem(
      itemKey: 'FL_CUSTOMERS',
      title: 'Customers',
      route: '/customers',
      iconName: 'people',
      sequenceNum: 40,
      widgetName: 'UserListCustomer',
    ),
    MenuItem(
      itemKey: 'FL_ACC_SALES',
      title: 'Sales Invoices',
      route: '/acct-sales',
      iconName: 'receipt_long',
      sequenceNum: 50,
      widgetName: 'SalesInvoiceList',
    ),
    MenuItem(
      itemKey: 'FL_ACC_PURCHASE',
      title: 'Purchase Invoices',
      route: '/acct-purchase',
      iconName: 'receipt',
      sequenceNum: 60,
      widgetName: 'PurchaseInvoiceList',
    ),
  ],
);

GoRouter createFreelanceTestRouter() {
  return createStaticAppRouter(
    menuConfig: freelanceTestMenuConfig,
    appTitle: 'GrowERP Freelance Test',
    dashboard: const Center(child: Text('Freelance test dashboard')),
    widgetBuilder: (route) => switch (route) {
      '/tasks' => const ActivityList(ActivityType.todo),
      '/hours' => const TimeEntryReportList(),
      '/customers' => const UserList(role: Role.customer),
      '/acct-sales' => const FinDocList(
        sales: true,
        docType: FinDocType.invoice,
        key: Key('SalesInvoice'),
      ),
      '/acct-purchase' => const FinDocList(
        sales: false,
        docType: FinDocType.invoice,
        key: Key('PurchaseInvoice'),
      ),
      _ => const Center(child: Text('Freelance test dashboard')),
    },
  );
}

Future<void> openTaskDetail(WidgetTester tester, String name) async {
  await CommonTest.selectOption(tester, '/tasks', 'ActivityList');
  await CommonTest.doNewSearch(tester, searchString: name);
  await CommonTest.checkWidgetKey(tester, 'ActivityDialog');
}

/// Close any dialogs left open (escape closes barrier-dismissible dialogs,
/// 'cancel' closes the activity detail dialog).
Future<void> closeDialogs(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    if (tester.any(find.byKey(const Key('TimeEntryListDialog'))) ||
        tester.any(find.byKey(const Key('TimeEntryDialog')))) {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      continue;
    }
    if (tester.any(find.byKey(const Key('ActivityDialog'))) &&
        tester.any(find.byKey(const Key('cancel')))) {
      await CommonTest.tapByKey(tester, 'cancel');
      continue;
    }
    break;
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''Freelance time billing workflow''', (tester) async {
    const taskName = 'Website maintenance';
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createFreelanceTestRouter(),
      freelanceTestMenuConfig,
      const [
        ActivityLocalizations.delegate,
        UserCompanyLocalizations.delegate,
        OrderAccountingLocalizations.delegate,
      ],
      restClient: restClient,
      blocProviders: [
        ...getUserCompanyBlocProviders(restClient, 'AppFreelance'),
        ...getOrderAccountingBlocProviders(restClient, 'AppFreelance'),
      ],
      title: "Freelance billing test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // 1. create a client
    await CommonTest.selectOption(tester, '/customers', 'UserListCustomer');
    await UserTest.addUsers(tester, [customers[0]], check: false);

    // 2. create a task for the client with an hourly rate of 50
    await CommonTest.selectOption(tester, '/tasks', 'ActivityList');
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.checkWidgetKey(tester, 'ActivityDialog');
    await CommonTest.enterText(tester, 'name', taskName);
    await CommonTest.drag(tester);
    await CommonTest.enterText(tester, 'description', 'Monthly maintenance');
    await CommonTest.enterText(tester, 'rate', '50');
    await CommonTest.enterAutocompleteValue(
      tester,
      'thirdParty',
      customers[0].firstName!,
    );
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'update');
    await CommonTest.waitForSnackbarToGo(tester);

    // 3. enter 4 hours on the task
    await openTaskDetail(tester, taskName);
    await CommonTest.tapByKey(tester, 'TimeEntries');
    await CommonTest.checkWidgetKey(tester, 'TimeEntryListDialog');
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.checkWidgetKey(tester, 'TimeEntryDialog');
    await CommonTest.enterText(tester, 'hours', '4');
    await CommonTest.enterText(tester, 'comments', 'fixed the website');
    await CommonTest.tapByKey(tester, 'update');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    // close any dialogs still open (list dialog pops on success)
    await closeDialogs(tester);

    // 4. approve the hours (admin)
    await openTaskDetail(tester, taskName);
    await CommonTest.tapByKey(tester, 'TimeEntries');
    await CommonTest.checkWidgetKey(tester, 'TimeEntryListDialog');
    expect(CommonTest.getTextField('status0'), 'inProcess');
    await CommonTest.tapByKey(tester, 'approve0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await closeDialogs(tester);

    // check approved
    await openTaskDetail(tester, taskName);
    await CommonTest.tapByKey(tester, 'TimeEntries');
    expect(CommonTest.getTextField('status0'), 'approved');
    await closeDialogs(tester);

    // 5. sales invoice for the client: 4 hours x 50 = 200
    await CommonTest.selectOption(tester, '/tasks', 'ActivityList');
    await CommonTest.tapByKey(tester, 'invoiceHours');
    await CommonTest.checkWidgetKey(tester, 'TimeEntryInvoiceDialog');
    await CommonTest.enterAutocompleteValue(
      tester,
      'clientSearch',
      customers[0].firstName!,
    );
    await CommonTest.tapByKey(tester, 'createInvoice');
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.selectOption(tester, '/acct-sales', 'SalesInvoice');
    expect(await CommonTest.waitForKey(tester, 'grandTotal0'), true);
    expect(CommonTest.getTextField('grandTotal0'), contains('200'));

    // 6. purchase (self-billing) invoice for the assistant: 4 x 30 = 120
    await CommonTest.selectOption(tester, '/tasks', 'ActivityList');
    await CommonTest.tapByKey(tester, 'invoiceHours');
    await CommonTest.checkWidgetKey(tester, 'TimeEntryInvoiceDialog');
    await CommonTest.tapByKey(tester, 'invoiceType');
    await CommonTest.tapByText(tester, 'Purchase invoice for assistant');
    await CommonTest.enterAutocompleteValue(
      tester,
      'assistantSearch',
      admin.firstName!,
    );
    await CommonTest.enterText(tester, 'hourlyRate', '30');
    await CommonTest.tapByKey(tester, 'createInvoice');
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.selectOption(tester, '/acct-purchase', 'PurchaseInvoice');
    expect(await CommonTest.waitForKey(tester, 'grandTotal0'), true);
    expect(CommonTest.getTextField('grandTotal0'), contains('120'));

    // 7. hours report: the 4 hours show as invoiced
    await CommonTest.selectOption(tester, '/hours', 'timeEntryReport');
    expect(await CommonTest.waitForKey(tester, 'invoicedHours0'), true);
    expect(CommonTest.getTextField('invoicedHours0'), '4');

    await CommonTest.logout(tester);
  });
}
