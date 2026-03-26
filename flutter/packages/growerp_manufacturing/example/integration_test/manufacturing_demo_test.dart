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
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_order_accounting/src/accounting/integration_test/transaction_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/payment_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/shipment_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/main.dart';

// ── Test data ─────────────────────────────────────────────────────────────────

/// Products for the manufacturing demo:
///   MFG-ASSY-001  Widget Assembly (finished good)
///   MFG-COMP-A    Bolt M5         (component, 2 per assembly)
///   MFG-COMP-B    Bearing 6201    (component, 1 per assembly)
final List<Product> mfgDemoProducts = [
  Product(
    pseudoId: 'MFG-ASSY-001',
    productName: 'Widget Assembly',
    productTypeId: 'Physical Good',
    price: Decimal.parse('50.00'),
    listPrice: Decimal.parse('60.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'MFG-COMP-A',
    productName: 'Bolt M5',
    productTypeId: 'Physical Good',
    price: Decimal.parse('1.00'),
    listPrice: Decimal.parse('1.20'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'MFG-COMP-B',
    productName: 'Bearing 6201',
    productTypeId: 'Physical Good',
    price: Decimal.parse('5.00'),
    listPrice: Decimal.parse('6.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
];

/// Production routing for Widget Assembly
final Routing mfgDemoRouting = Routing(routingName: 'Widget Assembly Process');
final List<RoutingTask> mfgDemoRoutingTasks = [
  RoutingTask(
    taskName: 'Prepare Components',
    sequenceNum: 10,
    estimatedWorkTime: Decimal.parse('0.5'),
  ),
  RoutingTask(
    taskName: 'Assemble',
    sequenceNum: 20,
    estimatedWorkTime: Decimal.parse('1.0'),
  ),
  RoutingTask(
    taskName: 'Quality Check',
    sequenceNum: 30,
    estimatedWorkTime: Decimal.parse('0.25'),
  ),
];

/// BOM: Widget Assembly → 2 × Bolt M5, 1 × Bearing 6201
final List<BomItem> mfgDemoBomItems = [
  BomItem(
    productId: 'MFG-ASSY-001',
    toProductId: 'MFG-COMP-A',
    quantity: Decimal.parse('2'),
  ),
  BomItem(
    productId: 'MFG-ASSY-001',
    toProductId: 'MFG-COMP-B',
    quantity: Decimal.parse('1'),
  ),
];

/// Sales order: 1 unit of Widget Assembly
final List<FinDoc> mfgDemoSalesOrders = [
  FinDoc(
    sales: true,
    docType: FinDocType.order,
    description: 'Manufacturing demo sales order',
    otherCompany: customerCompanies[1],
    items: [
      FinDocItem(
        description: 'Widget Assembly',
        quantity: Decimal.parse('1'),
        price: Decimal.parse('50.00'),
      ),
    ],
  ),
];

/// Purchase order: enough components to satisfy the WO
///   5 × Bolt M5, 3 × Bearing 6201
final List<FinDoc> mfgDemoPurchaseOrders = [
  FinDoc(
    sales: false,
    docType: FinDocType.order,
    description: 'Manufacturing demo purchase order',
    otherCompany: supplierCompanies[0],
    items: [
      FinDocItem(
        description: 'Bolt M5',
        quantity: Decimal.parse('5'),
        price: Decimal.parse('1.00'),
      ),
      FinDocItem(
        description: 'Bearing 6201',
        quantity: Decimal.parse('3'),
        price: Decimal.parse('5.00'),
      ),
    ],
  ),
];


// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createAdminMfgDemoRouter() {
  return createStaticAppRouter(
    menuConfig: adminMfgDemoMenuConfig,
    appTitle: 'GrowERP Manufacturing Demo',
    dashboard: const _MfgDemoDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/orders' => const FinDocList(
        key: Key('SalesOrder'),
        sales: true,
        docType: FinDocType.order,
      ),
      '/purchase-orders' => const FinDocList(
        key: Key('PurchaseOrder'),
        sales: false,
        docType: FinDocType.order,
      ),
      '/shipments' => const FinDocList(
        key: Key('ShipmentsOut'),
        sales: true,
        docType: FinDocType.shipment,
      ),
      '/incoming-shipments' => const FinDocList(
        key: Key('ShipmentsIn'),
        sales: false,
        docType: FinDocType.shipment,
      ),
      '/accounting' => const AccountingDashboard(),
      '/manufacturing/bom' => const BomList(),
      '/manufacturing/workOrder' => const WorkOrderList(),
      '/manufacturing/routing' => const RoutingList(),
      _ => const _MfgDemoDashboard(),
    },
    shellRoutes: [
      GoRoute(
        path: '/accounting/ledger',
        builder: (_, _) => const FinDocList(
          key: Key('Transaction'),
          sales: true,
          docType: FinDocType.transaction,
        ),
      ),
      GoRoute(
        path: '/accounting/sales_payments',
        builder: (_, _) => const FinDocList(
          key: Key('SalesPayment'),
          sales: true,
          docType: FinDocType.payment,
        ),
      ),
      GoRoute(
        path: '/accounting/purchase_payments',
        builder: (_, _) => const FinDocList(
          key: Key('PurchasePayment'),
          sales: false,
          docType: FinDocType.payment,
        ),
      ),
    ],
    additionalRoutes: [
      GoRoute(
        path: '/findoc',
        builder: (context, state) =>
            ShowFinDocDialog(state.extra as FinDoc? ?? FinDoc()),
      ),
    ],
  );
}

const adminMfgDemoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADMIN_MFG_DEMO',
  appId: 'admin_mfg_demo',
  name: 'GrowERP Manufacturing Demo',
  menuItems: [
    MenuItem(
      itemKey: 'MFG_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'MfgDemoDashboard',
    ),
    MenuItem(
      itemKey: 'MFG_BOM',
      title: 'BOM',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 20,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'MFG_WO',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 30,
      widgetName: 'WorkOrderList',
    ),
    MenuItem(
      itemKey: 'MFG_ROUTING',
      title: 'Routings',
      route: '/manufacturing/routing',
      iconName: 'route',
      sequenceNum: 35,
      widgetName: 'RoutingList',
    ),
    MenuItem(
      itemKey: 'MFG_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 50,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_IN_SHIP',
      title: 'Shipment-In',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_OUT_SHIP',
      title: 'Shipment-out',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 70,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_ACCT',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 80,
    ),
  ],
);

class _MfgDemoDashboard extends StatelessWidget {
  const _MfgDemoDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = adminMfgDemoMenuConfig.menuItems
            .where((item) =>
                item.isActive && item.route != null && item.route != '/')
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          key: const Key('MfgDemoDashboard'),
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardItems,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
            chartBuilder: (route) {
              if (route == '/accounting') {
                return const RevenueExpenseChartMini();
              }
              return null;
            },
          ),
        );
      },
    );
  }
}

// ── Demo entry point ──────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP Manufacturing Demo', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createAdminMfgDemoRouter(),
      adminMfgDemoMenuConfig,
      delegates,
      blocProviders: getAdminBlocProviders(restClient, 'AppAdmin'),
      restClient: restClient,
      title: 'GrowERP Manufacturing Demo',
      clear: true,
    );

    await CommonTest.showDemoStep(
      tester,
      'Manufacturing Demo',
      'An end-to-end walkthrough: BOM, sales order, work order, '
          'purchase, receive, production, shipping, and accounting.',
    );

    // ── Setup: load products, BOM, locations and trading partners ─────────────
    await CommonTest.showDemoStep(
      tester,
      'Setting Up Demo Data',
      'Loading products, Bill of Materials, warehouse locations, '
          'customer and supplier companies into a fresh company.',
      seconds: 3,
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        'products': mfgDemoProducts,
        'bomItems': mfgDemoBomItems,
        'locations': locations.sublist(0, 1),
        'companies': [customerCompanies[1], supplierCompanies[0]],
      },
    );

    // ── Phase 1: Bill of Materials ────────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Bill of Materials',
      'Viewing the BOM for "Widget Assembly".\n'
          'It requires 2 × Bolt M5 and 1 × Bearing 6201 per unit.',
      seconds: 3,
    );
    await BomTest.selectBom(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await BomTest.openBom(tester, 'MFG-ASSY-001');
    // Pause so the viewer can see the BOM detail screen.
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 2: Production routing ───────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Production Routing',
      'Creating a routing that defines the assembly steps.\n'
          '3 operations: Prepare Components → Assemble → Quality Check.',
      seconds: 3,
    );
    await RoutingTest.selectRoutings(tester);
    await RoutingTest.addRoutings(tester, [mfgDemoRouting]);
    await RoutingTest.openRouting(tester, 0);
    await RoutingTest.addRoutingTasks(tester, mfgDemoRoutingTasks);
    await RoutingTest.checkRoutingTasks(tester, mfgDemoRoutingTasks);
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 3: Sales order → auto-creates Work Order on approval ────────────
    await CommonTest.showDemoStep(
      tester,
      'Creating a Sales Order',
      'A customer orders 1 × Widget Assembly.\n'
          'Approving the order will automatically trigger a Work Order '
          'because the product has a Bill of Materials.',
      seconds: 3,
    );
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, mfgDemoSalesOrders);
    await OrderTest.approveOrders(tester);

    // Save approved sales order state for the outgoing shipment phase.
    final SaveTest testAfterSalesApprove = await PersistFunctions.getTest();
    final List<FinDoc> approvedSalesOrders = testAfterSalesApprove.orders;

    // ── Phase 4: Work Order — shortage + routing assignment ───────────────────
    await CommonTest.showDemoStep(
      tester,
      'Work Order Created Automatically',
      'The system created a Work Order for the Widget Assembly.\n'
          'It shows a material shortage because no components are in stock yet.\n'
          'We assign the production routing so shop floor steps are visible.',
      seconds: 3,
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    await tester.pump(const Duration(seconds: 2));
    await WorkOrderTest.assignRouting(tester, mfgDemoRouting.routingName!);
    // Re-open to show the routing steps embedded in the WO dialog
    await WorkOrderTest.openWorkOrder(tester, 0);
    await tester.pump(const Duration(seconds: 3));
    if (await CommonTest.doesExistKey(tester, 'cancel')) {
      await CommonTest.tapByKey(tester, 'cancel');
    } else if (await CommonTest.doesExistKey(tester, 'WorkOrderDialog')) {
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // ── Phase 5: Purchase order for components ────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Purchasing Components',
      'Creating a purchase order for 5 × Bolt M5 and 3 × Bearing 6201 '
          'to fulfil the Work Order requirements.\n'
          'The order is then approved and paid.',
      seconds: 3,
    );
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.addOrders(tester, mfgDemoPurchaseOrders);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 6: Receive components into warehouse ────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Receiving Components into Warehouse',
      'The incoming shipment from the supplier is approved and received.\n'
          'Components are now in stock and the Work Order shortage is resolved.',
      seconds: 3,
    );
    await ShipmentTest.selectIncomingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await ShipmentTest.receiveShipments(tester, locations.sublist(0, 1));

    // ── Phase 7: Production run ───────────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Running Production',
      'The Work Order is released, started, and then completed.\n'
          'Components are consumed and 1 × Widget Assembly is added to inventory.',
      seconds: 3,
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.releaseWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.startWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.completeWorkOrder(tester);

    // ── Phase 8: Ship to customer ─────────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Shipping to Customer',
      'The finished Widget Assembly is shipped to the customer.\n'
          'The outgoing shipment is approved, completed, and payment collected.',
      seconds: 3,
    );
    // Restore sales order context so the shipment step finds the right record.
    final SaveTest currentTest = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
      currentTest.copyWith(orders: approvedSalesOrders),
    );

    await ShipmentTest.selectOutgoingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await OrderTest.completeOrderShipments(tester);
    await PaymentTest.selectSalesPayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 9: Accounting ledger ────────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Accounting & GL Transactions',
      'All financial movements — inventory cost, COGS, revenue and payments — '
          'are automatically posted to the general ledger.',
      seconds: 3,
    );
    await TransactionTest.selectTransactions(tester);
    await CommonTest.waitForKey(tester, 'id0');
    // Pause so the viewer can see the ledger entries.
    await tester.pump(const Duration(seconds: 4));

    // ── Phase 10: Live dashboard summary ─────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Live Dashboard',
      'Ledger and statistics totals are being updated.\n'
          'The accounting dashboard now reflects the completed lifecycle.',
      seconds: 3,
    );
    await TransactionTest.showUpdatedAccountingDashboard(tester);

    await CommonTest.showDemoStep(
      tester,
      'Demo Complete',
      'You have seen the full GrowERP manufacturing lifecycle:\n'
          'BOM → Routing → Sales Order → Work Order → Purchase → Receive → '
          'Produce → Ship → Accounting → Dashboard.',
    );

    await CommonTest.logout(tester);
  });
}
