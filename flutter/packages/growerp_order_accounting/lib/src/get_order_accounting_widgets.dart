/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_order_accounting.dart';

/// Returns widget mappings for the order_accounting package
Map<String, GrowerpWidgetBuilder> getOrderAccountingWidgets() {
  return {
    // Sales Orders/Invoices/Payments/Shipments
    'SalesOrderList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.order,
    ),
    'SalesInvoiceList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.invoice,
    ),
    'SalesPaymentList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.payment,
    ),
    'OutgoingShipmentList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.shipment,
    ),

    // Purchase Orders/Invoices/Payments/Shipments
    'PurchaseOrderList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: false,
      docType: FinDocType.order,
    ),
    'PurchaseInvoiceList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: false,
      docType: FinDocType.invoice,
    ),
    'PurchasePaymentList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: false,
      docType: FinDocType.payment,
    ),
    'IncomingShipmentList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: false,
      docType: FinDocType.shipment,
    ),

    // Rental Orders
    'SalesOrderRentalList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.order,
      onlyRental: true,
    ),
    'CheckInList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.order,
      onlyRental: true,
      status: FinDocStatusVal.created,
    ),
    'CheckOutList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.order,
      onlyRental: true,
      status: FinDocStatusVal.approved,
    ),

    // Transactions
    'TransactionList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: true,
      docType: FinDocType.transaction,
    ),

    // Generic FinDocList
    'FinDocList': (args) => FinDocList(
      key: getKeyFromArgs(args),
      sales: args?['sales'] ?? true,
      docType: parseFinDocType(args?['docType']),
    ),

    // Accounting
    'LedgerTreeForm': (args) => const LedgerTreeForm(),
    'GlAccountList': (args) => const GlAccountList(),
    'LedgerJournalList': (args) => LedgerJournalList(key: getKeyFromArgs(args)),
    'RevenueExpenseChart': (args) => const RevenueExpenseChart(),
    'BalanceSheetForm': (args) => const BalanceSheetForm(),
    'BalanceSummaryList': (args) => const BalanceSummaryList(),
    'TimePeriodListForm': (args) => const TimePeriodListForm(),
    'ItemTypeList': (args) => const ItemTypeList(),
    'PaymentTypeList': (args) =>
        const PaymentTypeList(key: Key('PaymentTypeList')),
    'PrintingForm': (args) =>
        PrintingForm(finDocIn: args?['finDoc'] as FinDoc? ?? FinDoc()),
    'ShowFinDocDialog': (args) =>
        ShowFinDocDialog(args?['finDoc'] as FinDoc? ?? FinDoc()),
  };
}

/// True for `true`/`'true'`/`'1'` (query params arrive as strings).
bool _truthy(dynamic v) => v == true || v == 'true' || v == '1';

/// Parse an agent `presetStatus` arg (enum name, display name, or backend value)
/// into a [FinDocStatusVal]. Returns null when unset/unrecognised.
FinDocStatusVal? _parsePresetStatus(dynamic v) {
  if (v == null) return null;
  final s = v.toString().toLowerCase();
  for (final st in FinDocStatusVal.values) {
    if (st.name.toLowerCase() == s ||
        st.value.toLowerCase() == s ||
        st.toString().toLowerCase() == s) {
      return st;
    }
  }
  return null;
}

/// Build a [FinDocList] honoring agent-driven open args (openNew / finDocId /
/// presetStatus) so chat navigation lands on an operational, pre-filled screen.
FinDocList _finDocListFromArgs(
  Map<String, dynamic>? args, {
  required bool sales,
  required FinDocType docType,
}) {
  return FinDocList(
    key: getKeyFromArgs(args),
    sales: sales,
    docType: docType,
    openNew: _truthy(args?['openNew']),
    openFinDocId: (args?['finDocId'] ?? args?['pseudoId'] ?? args?['openFinDocId'])
        ?.toString(),
    presetStatus: _parsePresetStatus(args?['presetStatus']),
  );
}

/// Returns widget metadata for AI-powered navigation
List<WidgetMetadata> getOrderAccountingWidgetsWithMetadata() {
  return [
    // Sales documents
    WidgetMetadata(
      widgetName: 'SalesInvoiceList',
      description: 'List of sales invoices sent to customers',
      iconName: 'send',
      keywords: [
        'invoice',
        'bill',
        'sales',
        'AR',
        'accounts receivable',
        'customer invoice',
      ],
      parameters: {
        'status': 'Filter: open, in preparation, approved, completed',
      },
      builder: (args) => FinDocList(
        key: getKeyFromArgs(args),
        sales: true,
        docType: FinDocType.invoice,
      ),
    ),
    WidgetMetadata(
      widgetName: 'SalesOrderList',
      description: 'List of sales orders from customers. Use openNew=true to '
          'enter a new order, or finDocId+presetStatus=approved to approve one.',
      iconName: 'shopping_cart',
      keywords: ['order', 'sales', 'customer order', 'SO', 'enter order', 'approve order'],
      parameters: {
        'openNew': 'true → open the new sales order entry dialog',
        'finDocId': 'open this order (orderId or pseudoId)',
        'presetStatus': 'preset status dropdown, e.g. approved',
      },
      builder: (args) =>
          _finDocListFromArgs(args, sales: true, docType: FinDocType.order),
    ),
    WidgetMetadata(
      widgetName: 'SalesPaymentList',
      description: 'List of payments received from customers',
      iconName: 'money',
      keywords: [
        'payment',
        'receipt',
        'income',
        'customer payment',
        'AR payment',
      ],
      parameters: {'status': 'Filter: open, approved, completed'},
      builder: (args) => FinDocList(
        key: getKeyFromArgs(args),
        sales: true,
        docType: FinDocType.payment,
      ),
    ),
    WidgetMetadata(
      widgetName: 'OutgoingShipmentList',
      description: 'List of shipments sent to customers',
      iconName: 'local_shipping',
      keywords: ['shipment', 'delivery', 'shipping', 'outgoing', 'dispatch'],
      parameters: {'finDocId': 'open this shipment (shipmentId or pseudoId)'},
      builder: (args) =>
          _finDocListFromArgs(args, sales: true, docType: FinDocType.shipment),
    ),

    // Purchase documents
    WidgetMetadata(
      widgetName: 'PurchaseInvoiceList',
      description: 'List of purchase invoices from suppliers',
      iconName: 'call_received',
      keywords: [
        'invoice',
        'bill',
        'purchase',
        'AP',
        'accounts payable',
        'supplier invoice',
        'vendor invoice',
      ],
      parameters: {
        'status': 'Filter: open, in preparation, approved, completed',
      },
      builder: (args) => FinDocList(
        key: getKeyFromArgs(args),
        sales: false,
        docType: FinDocType.invoice,
      ),
    ),
    WidgetMetadata(
      widgetName: 'PurchaseOrderList',
      description: 'List of purchase orders to suppliers. Use openNew=true to '
          'enter a new order, or finDocId+presetStatus=approved to approve one.',
      iconName: 'shopping_bag',
      keywords: ['order', 'purchase', 'supplier order', 'vendor order', 'PO', 'approve order'],
      parameters: {
        'openNew': 'true → open the new purchase order entry dialog',
        'finDocId': 'open this order (orderId or pseudoId)',
        'presetStatus': 'preset status dropdown, e.g. approved',
      },
      builder: (args) =>
          _finDocListFromArgs(args, sales: false, docType: FinDocType.order),
    ),
    WidgetMetadata(
      widgetName: 'PurchasePaymentList',
      description: 'List of payments made to suppliers',
      iconName: 'money',
      keywords: [
        'payment',
        'expense',
        'supplier payment',
        'vendor payment',
        'AP payment',
      ],
      parameters: {'status': 'Filter: open, approved, completed'},
      builder: (args) => FinDocList(
        key: getKeyFromArgs(args),
        sales: false,
        docType: FinDocType.payment,
      ),
    ),
    WidgetMetadata(
      widgetName: 'IncomingShipmentList',
      description: 'List of shipments received from suppliers. Pass finDocId of '
          'an approved incoming shipment to open its receive screen.',
      iconName: 'local_shipping',
      keywords: [
        'shipment',
        'receiving',
        'receive shipment',
        'incoming',
        'receipt',
        'goods receipt',
      ],
      parameters: {
        'finDocId': 'open this shipment (shipmentId or pseudoId); an approved '
            'incoming shipment opens the receive dialog',
      },
      builder: (args) =>
          _finDocListFromArgs(args, sales: false, docType: FinDocType.shipment),
    ),

    // Accounting
    WidgetMetadata(
      widgetName: 'LedgerTreeForm',
      description: 'Chart of accounts tree view',
      iconName: 'account_tree',
      keywords: [
        'ledger',
        'chart of accounts',
        'COA',
        'GL',
        'general ledger',
        'accounts',
      ],
      builder: (args) => const LedgerTreeForm(),
    ),
    WidgetMetadata(
      widgetName: 'GlAccountList',
      description: 'List of general ledger accounts',
      iconName: 'account_balance',
      keywords: ['accounts', 'GL', 'general ledger', 'COA'],
      builder: (args) => const GlAccountList(),
    ),
    WidgetMetadata(
      widgetName: 'TransactionList',
      description: 'List of accounting transactions and journal entries',
      iconName: 'list',
      keywords: ['transaction', 'journal', 'entry', 'posting', 'accounting'],
      builder: (args) => FinDocList(
        key: getKeyFromArgs(args),
        sales: true,
        docType: FinDocType.transaction,
      ),
    ),
    WidgetMetadata(
      widgetName: 'BalanceSheetForm',
      description: 'Balance sheet financial report',
      iconName: 'assessment',
      keywords: [
        'balance sheet',
        'financial statement',
        'assets',
        'liabilities',
        'equity',
        'report',
      ],
      builder: (args) => const BalanceSheetForm(),
    ),
    WidgetMetadata(
      widgetName: 'RevenueExpenseChart',
      description: 'Revenue and expense chart visualization',
      iconName: 'assessment',
      keywords: [
        'revenue',
        'expense',
        'profit',
        'loss',
        'P&L',
        'income statement',
        'chart',
      ],
      builder: (args) => const RevenueExpenseChart(),
    ),
  ];
}
