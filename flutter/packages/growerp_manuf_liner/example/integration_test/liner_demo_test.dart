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
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_order_accounting/src/accounting/integration_test/transaction_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/shipment_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/main.dart' show getAdminBlocProviders, delegates;
import 'liner_test_app.dart';

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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
      createLinerExampleRouter(),
      linerExampleMenuConfig,
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
      'New user/company and set Up Demo Data',
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
    await CommonTest.gotoMainMenu(tester);

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
    await CommonTest.gotoMainMenu(tester);

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
    await WorkOrderTest.assignRouting(
      tester,
      linerDemoRoutings[0].routingName!,
    );
    // Re-open to add liner panels (routing steps now visible in dialog)
    await WorkOrderTest.openWorkOrder(tester, 0);
    // Pause to show the WO form with routing steps and shortage visible
    await tester.pump(const Duration(seconds: 2));
    // Add liner panels (embedded in the work order dialog via extraTabBuilder)
    await LinerPanelTest.addLinerPanels(tester, linerDemoPanels);
    await LinerPanelTest.checkLinerPanels(tester, linerDemoPanels.length);
    // Open first panel to verify computed fields
    await LinerPanelTest.checkComputedFields(tester, 0);
    if (await CommonTest.doesExistKey(tester, 'cancel')) {
      await CommonTest.tapByKey(tester, 'cancel'); // close WO dialog
    } else if (await CommonTest.doesExistKey(tester, 'WorkOrderDialog')) {
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await CommonTest.gotoMainMenu(tester);

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
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/purchase_payments',
      'PurchasePayment',
    );
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);
    await CommonTest.gotoMainMenu(tester);

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
    await CommonTest.gotoMainMenu(tester);

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
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await CommonTest.tapByKey(tester, 'closePrintPreview');

    await WorkOrderTest.completeWorkOrder(tester);
    await CommonTest.gotoMainMenu(tester);

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
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/sales_payments',
      'SalesPayment',
    );
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);
    await CommonTest.gotoMainMenu(tester);

    // ── Phase 10: Invoices ────────────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Purchase & Sales Invoices',
      'GrowERP auto-generates invoices from approved orders.\n'
          'The purchase invoice reflects the roll stock cost; '
          'the sales invoice captures revenue from the customer.',
    );
    await CommonTest.selectOption(
      tester,
      '/accounting/purchase_invoices',
      'PurchaseInvoice',
    );
    await tester.pump(const Duration(seconds: 3));

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/sales_invoices',
      'SalesInvoice',
    );
    await CommonTest.gotoMainMenu(tester);
    await tester.pump(const Duration(seconds: 3));

    // ── Phase 11: Accounting ──────────────────────────────────────────────────
    await showDemoStep(
      tester,
      'Accounting & GL Transactions',
      'All financial movements — inventory cost, COGS, revenue and payments — '
          'are automatically posted to the general ledger.',
    );
    await CommonTest.selectOption(tester, '/accounting/ledger', 'Transaction');
    await CommonTest.waitForKey(tester, 'id0');
    await tester.pump(const Duration(seconds: 4));
    await CommonTest.gotoMainMenu(tester);

    // ── Phase 12: Ledger Summarize & Statistics ───────────────────────────────
    await showDemoStep(
      tester,
      'Ledger Summarize & Statistics',
      'Recalculating ledger summaries and company statistics.\n'
          'All financial totals — assets, liabilities, revenue and costs — '
          'are refreshed so the dashboard reflects the completed job.',
    );
    await TransactionTest.showUpdatedAccountingDashboard(tester);

    // ── Phase 13: Revenue & Expense Report ───────────────────────────────────
    await showDemoStep(
      tester,
      'Revenue & Expense Report',
      'The general ledger report summarises all financial activity.\n'
          'Revenue from the sale and costs from purchasing and production '
          'are reflected here, showing the profit from this liner job.',
    );
    await CommonTest.selectOption(tester, '/accounting', 'AcctDashBoard');
    await CommonTest.selectOption(
      tester,
      '/accounting/reports',
      'RevenueExpenseChart',
    );
    await tester.pump(const Duration(seconds: 4));
    await CommonTest.gotoMainMenu(tester);

    await showDemoStep(
      tester,
      'Demo Complete',
      'You have seen the full GrowERP liner panel manufacturing lifecycle:\n'
          'Liner Types → Routing → BOM → Sales Order → Work Order → '
          'Liner Panels → Purchase → Receive → Produce → PDF → Ship → '
          'Purchase Invoice → Sales Invoice → Accounting → '
          'Summarize & Stats → Revenue Report.',
      seconds: 5,
    );

    await CommonTest.logout(tester);
  });
}
