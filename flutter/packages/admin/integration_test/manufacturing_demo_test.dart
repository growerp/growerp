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

// ── Demo helper ───────────────────────────────────────────────────────────────

/// Overlays a full-screen info card for [seconds] real seconds, then removes it.
Future<void> showDemoStep(
  WidgetTester tester,
  String title,
  String description, {
  int seconds = 3,
}) async {
  // Use the Navigator (inside MaterialApp's Localizations tree) as context.
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
  // Hold for [seconds] real seconds using small pump intervals.
  for (int i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  Navigator.of(element, rootNavigator: true).pop();
  await tester.pumpAndSettle();
}

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
      title: 'Incoming',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_OUT_SHIP',
      title: 'Outgoing',
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
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }
        return const Center(
          child: Text(
            'Manufacturing Demo Dashboard',
            key: Key('MfgDemoDashboard'),
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

    // ── Setup: load products, BOM, locations and trading partners ─────────────
    await showDemoStep(
      tester,
      'Setting Up Demo Data',
      'Loading products, Bill of Materials, warehouse locations, '
          'customer and supplier companies into a fresh company.',
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
    await showDemoStep(
      tester,
      'Bill of Materials',
      'Viewing the BOM for "Widget Assembly".\n'
          'It requires 2 × Bolt M5 and 1 × Bearing 6201 per unit.',
    );
    await BomTest.selectBom(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await BomTest.openBom(tester, 'MFG-ASSY-001');
    // Pause so the viewer can see the BOM detail screen.
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 2: Sales order → auto-creates Work Order on approval ────────────
    await showDemoStep(
      tester,
      'Creating a Sales Order',
      'A customer orders 1 × Widget Assembly.\n'
          'Approving the order will automatically trigger a Work Order '
          'because the product has a Bill of Materials.',
    );
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, mfgDemoSalesOrders);
    await OrderTest.approveOrders(tester);

    // Save approved sales order state for the outgoing shipment phase.
    final SaveTest testAfterSalesApprove = await PersistFunctions.getTest();
    final List<FinDoc> approvedSalesOrders = testAfterSalesApprove.orders;

    // ── Phase 3: Work Order — shortage ────────────────────────────────────────
    await showDemoStep(
      tester,
      'Work Order Created Automatically',
      'The system created a Work Order for the Widget Assembly.\n'
          'It shows a material shortage because no components are in stock yet.',
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    // Pause so the viewer can see the WO and shortage info.
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 4: Purchase order for components ────────────────────────────────
    await showDemoStep(
      tester,
      'Purchasing Components',
      'Creating a purchase order for 5 × Bolt M5 and 3 × Bearing 6201 '
          'to fulfil the Work Order requirements.\n'
          'The order is then approved and paid.',
    );
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.addOrders(tester, mfgDemoPurchaseOrders);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 5: Receive components into warehouse ────────────────────────────
    await showDemoStep(
      tester,
      'Receiving Components into Warehouse',
      'The incoming shipment from the supplier is approved and received.\n'
          'Components are now in stock and the Work Order shortage is resolved.',
    );
    await ShipmentTest.selectIncomingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await ShipmentTest.receiveShipments(tester, locations.sublist(0, 1));

    // ── Phase 6: Production run ───────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Running Production',
      'The Work Order is released, started, and then completed.\n'
          'Components are consumed and 1 × Widget Assembly is added to inventory.',
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.releaseWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.startWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.completeWorkOrder(tester);

    // ── Phase 7: Ship to customer ─────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Shipping to Customer',
      'The finished Widget Assembly is shipped to the customer.\n'
          'The outgoing shipment is approved, completed, and payment collected.',
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

    // ── Phase 8: Accounting ledger ────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Accounting & GL Transactions',
      'All financial movements — inventory cost, COGS, revenue and payments — '
          'are automatically posted to the general ledger.',
    );
    await TransactionTest.selectTransactions(tester);
    await CommonTest.waitForKey(tester, 'id0');
    // Pause so the viewer can see the ledger entries.
    await tester.pump(const Duration(seconds: 4));

    await showDemoStep(
      tester,
      'Demo Complete',
      'You have seen the full GrowERP manufacturing lifecycle:\n'
          'BOM → Sales Order → Work Order → Purchase → Receive → '
          'Produce → Ship → Accounting.',
      seconds: 5,
    );

    await CommonTest.logout(tester);
  });
}
