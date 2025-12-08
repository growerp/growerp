/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

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
    'PaymentTypeList': (args) => const PaymentTypeList(),
  };
}
