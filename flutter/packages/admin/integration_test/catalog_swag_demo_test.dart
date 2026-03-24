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

// ── Demo products ─────────────────────────────────────────────────────────────
//
//  SWAG-PKG-001  Moqui Marketing Package  (finished good — assembled from swag)
//  SWAG-CAP-001  Baseball Cap             (component, 1 per kit)
//  SWAG-MUG-001  Coffee Mug              (component, 1 per kit)
//  SWAG-USB-001  USB Drive               (component, 1 per kit)

// Note: SWAG-PKG-001 (Moqui Marketing Package) is NOT pre-loaded here.
// The BOM dialog creates it when the BOM is built through the UI.
final List<Product> swagProducts = [
  Product(
    pseudoId: 'SWAG-CAP-001',
    productName: 'Moqui Baseball Cap',
    productTypeId: 'Physical Good',
    price: Decimal.parse('8.00'),
    listPrice: Decimal.parse('10.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'SWAG-MUG-001',
    productName: 'Moqui Coffee Mug',
    productTypeId: 'Physical Good',
    price: Decimal.parse('7.00'),
    listPrice: Decimal.parse('9.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'SWAG-USB-001',
    productName: 'Moqui USB Drive',
    productTypeId: 'Physical Good',
    price: Decimal.parse('5.00'),
    listPrice: Decimal.parse('8.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
];

// BOM is created through the UI in this demo — no preloaded bomItems.

/// Sales order: 2 × Moqui Marketing Package
final List<FinDoc> swagSalesOrders = [
  FinDoc(
    sales: true,
    docType: FinDocType.order,
    description: 'Moqui swag order',
    otherCompany: customerCompanies[1],
    items: [
      FinDocItem(
        description: 'Moqui Marketing Package',
        quantity: Decimal.parse('2'),
        price: Decimal.parse('35.00'),
      ),
    ],
  ),
];

/// Purchase order: enough swag items to assemble 2 kits
///   3 × Baseball Cap, 3 × Coffee Mug, 3 × USB Drive
final List<FinDoc> swagPurchaseOrders = [
  FinDoc(
    sales: false,
    docType: FinDocType.order,
    description: 'Moqui swag components PO',
    otherCompany: supplierCompanies[0],
    items: [
      FinDocItem(
        description: 'Moqui Baseball Cap',
        quantity: Decimal.parse('3'),
        price: Decimal.parse('8.00'),
      ),
      FinDocItem(
        description: 'Moqui Coffee Mug',
        quantity: Decimal.parse('3'),
        price: Decimal.parse('7.00'),
      ),
      FinDocItem(
        description: 'Moqui USB Drive',
        quantity: Decimal.parse('3'),
        price: Decimal.parse('5.00'),
      ),
    ],
  ),
];

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createCatalogSwagDemoRouter() {
  return createStaticAppRouter(
    menuConfig: catalogSwagDemoMenuConfig,
    appTitle: 'GrowERP Catalog & Manufacturing Demo',
    dashboard: const _SwagDemoDashboard(),
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
      _ => const _SwagDemoDashboard(),
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

const catalogSwagDemoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CATALOG_SWAG_DEMO',
  appId: 'catalog_swag_demo',
  name: 'GrowERP Catalog & Manufacturing Demo',
  menuItems: [
    MenuItem(
      itemKey: 'SWAG_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'SwagDemoDashboard',
    ),
    MenuItem(
      itemKey: 'SWAG_BOM',
      title: 'BOM',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 20,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'SWAG_WO',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 30,
      widgetName: 'WorkOrderList',
    ),
    MenuItem(
      itemKey: 'SWAG_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'SWAG_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 50,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'SWAG_IN_SHIP',
      title: 'Incoming',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'SWAG_OUT_SHIP',
      title: 'Outgoing',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 70,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'SWAG_ACCT',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 80,
    ),
  ],
);

class _SwagDemoDashboard extends StatelessWidget {
  const _SwagDemoDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }
        return Center(
          key: const Key('SwagDemoDashboard'),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 40, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Icon(Icons.precision_manufacturing_outlined,
                          size: 40, color: Colors.blue.shade700),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Catalog & Manufacturing Demo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Products · Bills of Materials · Orders · Shipments · Accounting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
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

  testWidgets('GrowERP Catalog & Swag Manufacturing Demo', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createCatalogSwagDemoRouter(),
      catalogSwagDemoMenuConfig,
      delegates,
      blocProviders: getAdminBlocProviders(restClient, 'AppAdmin'),
      restClient: restClient,
      title: 'GrowERP Catalog & Manufacturing Demo',
      clear: true,
    );

    await CommonTest.showDemoStep(
      tester,
      'Catalog & Manufacturing Demo',
      'An end-to-end walkthrough: products, BOM, sales order, '
          'work order, components, assembly, shipping, and accounting.',
    );

    // ── Setup: catalog demo data + swag products ───────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Setting Up the Demo Company',
      'A fresh company is registered with the swag products, a warehouse '
          'location, and demo partners pre-loaded — no built-in catalog demo '
          'data is used.',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      demoData: false,
      testData: {
        'products': swagProducts,
        'locations': locations.sublist(0, 1),
        'companies': [customerCompanies[1], supplierCompanies[0]],
      },
    );

    // ── Phase 1: Create the Bill of Materials through the UI ──────────────────
    await CommonTest.showDemoStep(
      tester,
      'Creating the Bill of Materials',
      'The "Moqui Marketing Package" BOM is built interactively.\n'
          'It bundles 1 × Baseball Cap, 1 × Coffee Mug, and 1 × USB Drive '
          'into a single sellable kit.',
    );
    await BomTest.selectBom(tester);
    await BomTest.createBomWithComponents(
      tester,
      productName: 'Moqui Marketing Package',
      pseudoId: 'SWAG-PKG-001',
      components: [
        BomItem(
          componentPseudoId: 'SWAG-CAP-001',
          quantity: Decimal.parse('1'),
        ),
        BomItem(
          componentPseudoId: 'SWAG-MUG-001',
          quantity: Decimal.parse('1'),
        ),
        BomItem(
          componentPseudoId: 'SWAG-USB-001',
          quantity: Decimal.parse('1'),
        ),
      ],
    );
    // Pause so the viewer can see the completed BOM dialog.
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 2: Sales order → auto-creates Work Order on approval ────────────
    await CommonTest.showDemoStep(
      tester,
      'Receiving a Customer Order',
      'A customer orders 2 × Moqui Marketing Package.\n'
          'Approving the order automatically creates a Work Order because '
          'the product has a Bill of Materials.',
    );
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, swagSalesOrders);
    await OrderTest.approveOrders(tester);

    // Save approved sales order state for the outgoing shipment phase.
    final SaveTest testAfterSalesApprove = await PersistFunctions.getTest();
    final List<FinDoc> approvedSalesOrders = testAfterSalesApprove.orders;

    // ── Phase 3: Work Order with material shortage ────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Work Order — Material Shortage',
      'The system created a Work Order for the 2 kits.\n'
          'It shows a material shortage for all three components '
          'because no swag items are in the warehouse yet.',
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    // Pause so the viewer can see the WO and the shortage panel.
    await tester.pump(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 4: Purchase order for swag components ───────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Ordering Swag Components',
      'A purchase order is raised for 3 each of Baseball Cap, Coffee Mug, '
          'and USB Drive.\nThe order is approved and payment is processed.',
    );
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.addOrders(tester, swagPurchaseOrders);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 5: Receive components into warehouse ────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Receiving Components into the Warehouse',
      'The incoming shipment from the supplier is received.\n'
          'Caps, mugs and USB drives are now in stock and the Work Order '
          'shortage is cleared.',
    );
    await ShipmentTest.selectIncomingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await ShipmentTest.receiveShipments(tester, locations.sublist(0, 1));

    // ── Phase 6: Production run ───────────────────────────────────────────────
    await CommonTest.showDemoStep(
      tester,
      'Assembling the Kits',
      'The Work Order is released, started, and completed.\n'
          'Components are consumed and 2 × Moqui Marketing Package '
          'are added to finished-goods inventory.',
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
    await CommonTest.showDemoStep(
      tester,
      'Shipping to the Customer',
      'The finished kits are shipped to the customer.\n'
          'The outgoing shipment is approved, completed, and '
          'customer payment is collected.',
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
    await CommonTest.showDemoStep(
      tester,
      'Accounting & GL Transactions',
      'Every financial movement — inventory cost, COGS, revenue, and payments — '
          'is automatically posted to the general ledger.',
    );
    await TransactionTest.selectTransactions(tester);
    await CommonTest.waitForKey(tester, 'id0');
    // Pause so the viewer can see the ledger entries.
    await tester.pump(const Duration(seconds: 4));

    await CommonTest.showDemoStep(
      tester,
      'Demo Complete',
      'You have seen the full GrowERP catalog + manufacturing lifecycle:\n'
          'Catalog Demo Data → BOM (via UI) → Sales Order → Work Order → '
          'Purchase → Receive → Assemble → Ship → Accounting.',
      seconds: 5,
    );

    await CommonTest.logout(tester);
  });
}
