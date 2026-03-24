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

/// Products for the manufacturing lifecycle:
///   MFG-ASSY-001  Widget Assembly (finished good)
///   MFG-COMP-A    Bolt M5         (component, 2 per assembly)
///   MFG-COMP-B    Bearing 6201    (component, 1 per assembly)
final List<Product> mfgLifecycleProducts = [
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
/// For 1-unit WO: needs 2 Bolt M5 and 1 Bearing 6201
final List<BomItem> mfgBomItems = [
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
final List<FinDoc> mfgSalesOrders = [
  FinDoc(
    sales: true,
    docType: FinDocType.order,
    description: 'Manufacturing lifecycle sales order',
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
final List<FinDoc> mfgPurchaseOrders = [
  FinDoc(
    sales: false,
    docType: FinDocType.order,
    description: 'Manufacturing lifecycle purchase order',
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

GoRouter createAdminMfgTestRouter() {
  return createStaticAppRouter(
    menuConfig: adminMfgMenuConfig,
    appTitle: 'Admin Manufacturing Lifecycle Test',
    dashboard: const _MfgDashboard(),
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
      _ => const _MfgDashboard(),
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

const adminMfgMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADMIN_MFG_LIFECYCLE',
  appId: 'admin_mfg_lifecycle',
  name: 'Admin Manufacturing Lifecycle',
  menuItems: [
    MenuItem(
      itemKey: 'MFG_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'MfgDashboard',
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

class _MfgDashboard extends StatelessWidget {
  const _MfgDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }
        return const Center(
          child: Text(
            'Manufacturing Lifecycle Dashboard',
            key: Key('MfgDashboard'),
          ),
        );
      },
    );
  }
}

// ── Test entry point ──────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP Manufacturing Lifecycle', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createAdminMfgTestRouter(),
      adminMfgMenuConfig,
      delegates,
      blocProviders: getAdminBlocProviders(restClient, 'AppAdmin'),
      restClient: restClient,
      title: 'Manufacturing Lifecycle Test',
      clear: true,
    );

    // ── Phase 0: Setup ────────────────────────────────────────────────────────
    // Preload products, BOM, locations, and trading partners.
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        'products': mfgLifecycleProducts,
        'bomItems': mfgBomItems,
        'locations': locations.sublist(0, 1),
        'companies': [customerCompanies[1], supplierCompanies[0]],
      },
    );

    // ── Phase 1: Verify BOM was preloaded ─────────────────────────────────────
    await BomTest.selectBom(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await BomTest.openBom(tester, 'MFG-ASSY-001');
    await BomTest.checkBomComponents(tester, [
      BomItem(componentPseudoId: 'MFG-COMP-A'),
      BomItem(componentPseudoId: 'MFG-COMP-B'),
    ]);
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 2: Sales order → auto-creates WorkOrder on approval ─────────────
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, mfgSalesOrders);
    await OrderTest.approveOrders(tester);
    // Backend auto-creates a WorkOrder for 'Widget Assembly' (has BOM)

    // Save the approved sales orders state (includes invoiceId, paymentId, shipmentId)
    final SaveTest testAfterSalesApprove = await PersistFunctions.getTest();
    final List<FinDoc> approvedSalesOrders = testAfterSalesApprove.orders;

    // ── Phase 3: Verify auto-created WorkOrder shows shortage ─────────────────
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    // Open the auto-created WO and check shortage
    // BOM: CompA need 2, CompB need 1 — no stock yet
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.checkWorkOrderStatus(tester, 'In Planning');
    await WorkOrderTest.checkShortage(tester, [
      {'pseudoId': 'MFG-COMP-A', 'haveQty': '0'},
      {'pseudoId': 'MFG-COMP-B', 'haveQty': '0'},
    ]);
    await CommonTest.tapByKey(tester, 'cancel');

    // ── Phase 4: Purchase order for components ────────────────────────────────
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.addOrders(tester, mfgPurchaseOrders);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 5: Receive components into warehouse ────────────────────────────
    await ShipmentTest.selectIncomingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await ShipmentTest.receiveShipments(tester, locations.sublist(0, 1));
    await OrderTest.checkOrderShipmentsComplete(tester);

    // ── Phase 6: Production run — no shortage, release → start → complete ─────
    await WorkOrderTest.selectWorkOrders(tester);
    await CommonTest.waitForKey(tester, 'item0');
    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.checkWorkOrderStatus(tester, 'In Planning');
    // Components now have stock: Bolt M5 ≥ 2, Bearing 6201 ≥ 1 → no shortage
    await WorkOrderTest.releaseWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.checkWorkOrderStatus(tester, 'Approved');
    await WorkOrderTest.startWorkOrder(tester);

    await WorkOrderTest.openWorkOrder(tester, 0);
    await WorkOrderTest.checkWorkOrderStatus(tester, 'In Progress');
    await WorkOrderTest.completeWorkOrder(tester);
    // Components consumed; 1 unit of Widget Assembly produced in inventory

    // ── Phase 7: Ship to customer ─────────────────────────────────────────────
    // Restore sales order to SaveTest so approveOrderShipments finds correct shipment
    final SaveTest currentTest = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
      currentTest.copyWith(orders: approvedSalesOrders),
    );

    await ShipmentTest.selectOutgoingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await OrderTest.completeOrderShipments(tester);
    await OrderTest.checkOrderShipmentsComplete(tester);
    await PaymentTest.selectSalesPayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);

    // ── Phase 8: Verify ledger has transactions ───────────────────────────────
    await TransactionTest.selectTransactions(tester);
    await CommonTest.waitForKey(tester, 'id0');
    // Transactions should exist from order approval, shipment, WO completion

    await CommonTest.logout(tester);
  });
}
