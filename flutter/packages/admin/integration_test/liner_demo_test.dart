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
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
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

/// Liner types (plastic materials used in the factory)
final List<LinerType> linerDemoLinerTypes = [
  LinerType(
    linerName: '60 mil HDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.306'),
  ),
  LinerType(
    linerName: '40 mil LLDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.204'),
  ),
];

/// Production routing for liner manufacturing
final List<Routing> linerDemoRoutings = [
  Routing(
    routingName: 'Standard Liner',
    description: 'Cut → Seam → QC Inspection → Fold & Package',
  ),
];
final List<RoutingTask> linerDemoRoutingTasks = [
  RoutingTask(
    taskName: 'Cut',
    sequenceNum: 10,
    estimatedWorkTime: Decimal.parse('0.5'),
    workCenterName: 'Cutting Station',
  ),
  RoutingTask(
    taskName: 'Seam',
    sequenceNum: 20,
    estimatedWorkTime: Decimal.parse('1.0'),
    workCenterName: 'Welding Station',
  ),
  RoutingTask(
    taskName: 'QC Inspection',
    sequenceNum: 30,
    estimatedWorkTime: Decimal.parse('0.25'),
    workCenterName: 'QC Station',
  ),
  RoutingTask(
    taskName: 'Fold & Package',
    sequenceNum: 40,
    estimatedWorkTime: Decimal.parse('0.5'),
    workCenterName: 'Packaging Station',
  ),
];

/// Products:
///   LINER-ROLL-60   60 mil HDPE Roll Stock  (raw material)
///   LINER-SYS-60    Pond Liner System 60mil  (finished good, sold to customers)
final List<Product> linerDemoProducts = [
  Product(
    pseudoId: 'LINER-ROLL-60',
    productName: '60mil HDPE Roll Stock',
    productTypeId: 'Physical Good',
    price: Decimal.parse('1.50'),
    listPrice: Decimal.parse('1.75'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'LINER-SYS-60',
    productName: 'Pond Liner System 60mil',
    productTypeId: 'Physical Good',
    price: Decimal.parse('2.00'),
    listPrice: Decimal.parse('2.40'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
];

/// BOM: Pond Liner System 60mil → 1 × 60mil HDPE Roll Stock
final List<BomItem> linerDemoBomItems = [
  BomItem(
    productId: 'LINER-SYS-60',
    toProductId: 'LINER-ROLL-60',
    quantity: Decimal.parse('1'),
  ),
];

/// Sales order: customer orders 1 liner system
final List<FinDoc> linerDemoSalesOrders = [
  FinDoc(
    sales: true,
    docType: FinDocType.order,
    description: 'Pond liner installation — Phase 1',
    otherCompany: customerCompanies[1],
    items: [
      FinDocItem(
        description: 'Pond Liner System 60mil',
        quantity: Decimal.parse('1'),
        price: Decimal.parse('2.00'),
      ),
    ],
  ),
];

/// Purchase order: buy 5 rolls of roll stock from supplier
final List<FinDoc> linerDemoPurchaseOrders = [
  FinDoc(
    sales: false,
    docType: FinDocType.order,
    description: 'Roll stock replenishment',
    otherCompany: supplierCompanies[0],
    items: [
      FinDocItem(
        description: '60mil HDPE Roll Stock',
        quantity: Decimal.parse('5'),
        price: Decimal.parse('1.50'),
      ),
    ],
  ),
];

/// Liner panels for the work order (two sample panels)
final List<LinerPanel> linerDemoPanels = [
  LinerPanel(
    linerTypeId: '60 mil HDPE',
    panelName: 'Panel 1',
    panelWidth: Decimal.parse('45'),
    panelLength: Decimal.parse('100'),
  ),
  LinerPanel(
    linerTypeId: '60 mil HDPE',
    panelName: 'Panel 2',
    panelWidth: Decimal.parse('22.5'),
    panelLength: Decimal.parse('50'),
  ),
];

// ── Demo helper ───────────────────────────────────────────────────────────────

/// Overlays a full-screen info card for [seconds] real seconds, then removes it.
Future<void> showDemoStep(
  WidgetTester tester,
  String title,
  String description, {
  int seconds = 3,
}) async {
  final element = tester.element(find.byType(Navigator).last);
  showDialog(
    context: element,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (int i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  Navigator.of(element, rootNavigator: true).pop();
  await tester.pumpAndSettle();
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createLinerDemoRouter() {
  return createStaticAppRouter(
    menuConfig: linerDemoMenuConfig,
    appTitle: 'GrowERP Liner Demo',
    dashboard: const _LinerDemoDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/liner/linerType' => const LinerTypeList(),
      '/manufacturing/routing' => const RoutingList(),
      '/manufacturing/bom' => const BomList(),
      '/manufacturing/workOrder' => WorkOrderList(
          extraTabBuilder: (workOrder) => [
            SizedBox(
              height: 300,
              child: LinerPanelList(workEffortId: workOrder.workEffortId),
            ),
          ],
          extraActionBuilder: (workOrder) => [
            Tooltip(
              message: 'Print Production Order',
              child: IconButton(
                key: const Key('printProductionOrder'),
                icon: const Icon(Icons.print),
                onPressed: () => printProductionOrder(workOrder),
              ),
            ),
          ],
        ),
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
      _ => const _LinerDemoDashboard(),
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

const linerDemoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'LINER_DEMO',
  appId: 'liner_demo',
  name: 'GrowERP Liner Demo',
  menuItems: [
    MenuItem(
      itemKey: 'LINER_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'LinerDemoDashboard',
    ),
    MenuItem(
      itemKey: 'LINER_TYPES',
      title: 'Liner Types',
      route: '/liner/linerType',
      iconName: 'layers',
      sequenceNum: 20,
      widgetName: 'LinerTypeList',
    ),
    MenuItem(
      itemKey: 'LINER_ROUTING',
      title: 'Routing',
      route: '/manufacturing/routing',
      iconName: 'route',
      sequenceNum: 30,
      widgetName: 'RoutingList',
    ),
    MenuItem(
      itemKey: 'LINER_BOM',
      title: 'BOM',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 40,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'LINER_WO',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 50,
      widgetName: 'WorkOrderList',
    ),
    MenuItem(
      itemKey: 'LINER_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 70,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_IN_SHIP',
      title: 'Shipment-In',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 80,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_OUT_SHIP',
      title: 'Shipment-out',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 90,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_ACCT',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 100,
    ),
  ],
);

class _LinerDemoDashboard extends StatelessWidget {
  const _LinerDemoDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }
        return const Center(
          child: Text(
            'Liner Panel Manufacturing Demo',
            key: Key('LinerDemoDashboard'),
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

  testWidgets('GrowERP Liner Panel Manufacturing Demo', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createLinerDemoRouter(),
      linerDemoMenuConfig,
      delegates,
      blocProviders: [
        ...getAdminBlocProviders(restClient, 'AppAdmin'),
        ...getLinerBlocProviders(restClient),
      ],
      restClient: restClient,
      title: 'GrowERP Liner Panel Manufacturing Demo',
      clear: true,
    );

    // ── Setup ─────────────────────────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Setting Up Demo Data',
      'Loading products, Bill of Materials, warehouse location, '
          'and trading partners into a fresh company.',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        'products': linerDemoProducts,
        'bomItems': linerDemoBomItems,
        'locations': locations.sublist(0, 1),
        'companies': [customerCompanies[1], supplierCompanies[0]],
      },
    );

    // ── Phase 1: Liner Types ──────────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Liner Types — Material Catalog',
      'Defining the plastic materials used in the factory.\n'
          '"60 mil HDPE" with 22.5 ft width increment and 0.306 lb/sqft '
          'drives all automatic panel calculations.',
    );
    await LinerTypeTest.selectLinerTypes(tester);
    await LinerTypeTest.addLinerTypes(tester, linerDemoLinerTypes);
    // Pause so viewer can read the liner type table
    await tester.pump(const Duration(seconds: 3));

    // ── Phase 2: Production Routing ───────────────────────────────────────────
    await showDemoStep(
      tester,
      'Production Routing',
      'A routing defines the sequence of operations on the shop floor.\n'
          '"Standard Liner" follows: Cut → Seam → QC Inspection → Fold & Package.',
    );
    await RoutingTest.selectRoutings(tester);
    await RoutingTest.addRoutings(tester, linerDemoRoutings);
    await RoutingTest.openRouting(tester, 0);
    await RoutingTest.addRoutingTasks(tester, linerDemoRoutingTasks);
    await RoutingTest.checkRoutingTasks(tester, linerDemoRoutingTasks);
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 3: Bill of Materials ────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Bill of Materials',
      'Viewing the BOM for "Pond Liner System 60mil".\n'
          'It requires 1 × 60mil HDPE Roll Stock per system.',
    );
    await BomTest.selectBom(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await BomTest.openBom(tester, 'LINER-SYS-60');
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 4: Sales Order → auto Work Order ────────────────────────────────
    await showDemoStep(
      tester,
      'Creating a Sales Order',
      'A customer orders 1 × Pond Liner System 60mil.\n'
          'Approving the order automatically creates a Work Order '
          'because the product has a Bill of Materials.',
    );
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, linerDemoSalesOrders);
    await OrderTest.approveOrders(tester);

    // Save approved sales order for the outgoing shipment phase
    final SaveTest testAfterSalesApprove = await PersistFunctions.getTest();
    final List<FinDoc> approvedSalesOrders = testAfterSalesApprove.orders;

    // ── Phase 5: Work Order — add liner panels ────────────────────────────────
    await showDemoStep(
      tester,
      'Work Order — Liner Panels',
      'The Work Order was created automatically.\n'
          'Now we enter the individual liner panels for this job. '
          'The system computes SqFt, Passes and Weight for each panel.',
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    // Assign the production routing first
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.assignRouting(tester, linerDemoRoutings[0].routingName!);
    // Re-open to add liner panels (routing steps now visible in dialog)
    await WorkOrderTest.openWorkOrder(tester, 0);
    // Pause to show the WO form with routing steps and shortage visible
    await tester.pump(const Duration(seconds: 2));
    // Add liner panels (embedded in the work order dialog via extraTabBuilder)
    await LinerPanelTest.addLinerPanels(tester, linerDemoPanels);
    await LinerPanelTest.checkLinerPanels(tester, linerDemoPanels.length);
    // Open first panel to verify computed fields
    await LinerPanelTest.checkComputedFields(tester, 0);
    await CommonTest.tapByKey(tester, 'cancel'); // close WO dialog

    // ── Phase 6: Purchase roll stock ──────────────────────────────────────────
    await showDemoStep(
      tester,
      'Purchasing Roll Stock',
      'The Work Order shows a material shortage — no roll stock in inventory.\n'
          'Creating a purchase order for 5 rolls from our supplier.',
    );
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.addOrders(tester, linerDemoPurchaseOrders);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 7: Receive roll stock ───────────────────────────────────────────
    await showDemoStep(
      tester,
      'Receiving Roll Stock into Warehouse',
      'Approving and receiving the incoming shipment.\n'
          'Roll stock is now in inventory — the Work Order shortage is resolved.',
    );
    await ShipmentTest.selectIncomingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await ShipmentTest.receiveShipments(tester, locations.sublist(0, 1));

    // ── Phase 8: Complete production + print PDF ──────────────────────────────
    await showDemoStep(
      tester,
      'Running Production',
      'Releasing, starting, and completing the Work Order.\n'
          'Roll stock is consumed and 1 × Pond Liner System is added to inventory.\n'
          'The Print button generates a shop-floor production order PDF.',
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.releaseWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.startWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    // Tap print button to demonstrate PDF generation
    await CommonTest.tapByKey(tester, 'printProductionOrder');
    await tester.pump(const Duration(seconds: 2));
    await CommonTest.tapByKey(tester, 'cancel');

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.completeWorkOrder(tester);

    // ── Phase 9: Ship to customer ─────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Shipping to Customer',
      'The finished liner system is shipped to the customer.\n'
          'Outgoing shipment approved, completed, and payment collected.',
    );
    // Restore sales order context so shipment step finds the right record
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

    // ── Phase 10: Accounting ──────────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Accounting & GL Transactions',
      'All financial movements — inventory cost, COGS, revenue and payments — '
          'are automatically posted to the general ledger.',
    );
    await TransactionTest.selectTransactions(tester);
    await CommonTest.waitForKey(tester, 'id0');
    await tester.pump(const Duration(seconds: 4));

    await showDemoStep(
      tester,
      'Demo Complete',
      'You have seen the full GrowERP liner panel manufacturing lifecycle:\n'
          'Liner Types → Routing → BOM → Sales Order → Work Order → '
          'Liner Panels → Purchase → Receive → Produce → PDF → Ship → Accounting.',
      seconds: 5,
    );

    await CommonTest.logout(tester);
  });
}
