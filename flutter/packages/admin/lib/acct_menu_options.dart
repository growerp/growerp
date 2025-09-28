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
import 'package:admin/views/plan_selection_form.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

import 'views/accounting_form.dart';

List<MenuOption> getAcctMenuOptions(BuildContext context) => [
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: CoreLocalizations.of(context)!.accountingDashboard,
    route: '/accounting',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const AccountingForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/orderGrey.png",
    selectedImage: "packages/growerp_core/images/order.png",
    title: CoreLocalizations.of(context)!.accountingSales,
    route: '/acctSales',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("SalesInvoice"),
          sales: true,
          docType: FinDocType.invoice,
        ),
        label: CoreLocalizations.of(context)!.outgoingInvoices,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("SalesPayment"),
          sales: true,
          docType: FinDocType.payment,
        ),
        label: CoreLocalizations.of(context)!.incomingPayments,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: CoreLocalizations.of(context)!.customers,
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/supplierGrey.png",
    selectedImage: "packages/growerp_core/images/supplier.png",
    title: CoreLocalizations.of(context)!.accountingPurch,
    route: '/acctPurchase',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("PurchaseInvoice"),
          sales: false,
          docType: FinDocType.invoice,
        ),
        label: CoreLocalizations.of(context)!.incomingInvoices,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("PurchasePayment"),
          sales: false,
          docType: FinDocType.payment,
        ),
        label: CoreLocalizations.of(context)!.outgoingPayments,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Supplier'), role: Role.supplier),
        label: CoreLocalizations.of(context)!.suppliers,
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: CoreLocalizations.of(context)!.accountingLedger,
    route: '/acctLedger',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const LedgerTreeForm(),
        label: CoreLocalizations.of(context)!.ledgerTree,
        icon: const Icon(Icons.account_tree),
      ),
      TabItem(
        form: const GlAccountList(),
        label: CoreLocalizations.of(context)!.ledgerAccnt,
        icon: const Icon(Icons.format_list_bulleted),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("Transaction"),
          sales: true,
          docType: FinDocType.transaction,
        ),
        label: CoreLocalizations.of(context)!.ledgerTransaction,
        icon: const Icon(Icons.view_list),
      ),
      TabItem(
        form: const LedgerJournalList(key: Key("LedgerJournal")),
        label: CoreLocalizations.of(context)!.ledgerJournals,
        icon: const Icon(Icons.checklist),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/reportGrey.png",
    selectedImage: "packages/growerp_core/images/report.png",
    title: CoreLocalizations.of(context)!.reports,
    route: '/acctReports',
    tabItems: [
      TabItem(
        form: const RevenueExpenseChart(),
        label: CoreLocalizations.of(context)!.revenueExpense,
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const BalanceSheetForm(),
        label: CoreLocalizations.of(context)!.balanceSheet,
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const BalanceSummaryList(),
        label: CoreLocalizations.of(context)!.balanceSummary,
        icon: const Icon(Icons.list),
      ),
    ],
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: "packages/growerp_core/images/setupGrey.png",
    selectedImage: "packages/growerp_core/images/setup.png",
    title: CoreLocalizations.of(context)!.setUp,
    route: '/acctSetup',
    tabItems: [
      TabItem(
        form: const TimePeriodListForm(),
        label: CoreLocalizations.of(context)!.timePeriods,
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const ItemTypeList(),
        label: CoreLocalizations.of(context)!.itemTypes,
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const PaymentTypeList(),
        label: CoreLocalizations.of(context)!.paymtTypes,
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const PlanSelectionForm(),
        label: CoreLocalizations.of(context)!.planSelection,
        icon: const Icon(Icons.subscriptions),
      ),
    ],
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: CoreLocalizations.of(context)!.mainDashboard,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
];

// Function for localized menu options (replaces global variable)
List<MenuOption> acctMenuOptions(BuildContext context) => [
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: CoreLocalizations.of(context)!.accountingDashboard,
    route: '/accounting',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const AccountingForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/orderGrey.png",
    selectedImage: "packages/growerp_core/images/order.png",
    title: CoreLocalizations.of(context)!.accountingSales,
    route: '/acctSales',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("SalesInvoice"),
          sales: true,
          docType: FinDocType.invoice,
        ),
        label: "Outgoing Invoices",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("SalesPayment"),
          sales: true,
          docType: FinDocType.payment,
        ),
        label: "Incoming Payments",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/supplierGrey.png",
    selectedImage: "packages/growerp_core/images/supplier.png",
    title: CoreLocalizations.of(context)!.accountingPurch,
    route: '/acctPurchase',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("PurchaseInvoice"),
          sales: false,
          docType: FinDocType.invoice,
        ),
        label: "Incoming Invoices",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("PurchasePayment"),
          sales: false,
          docType: FinDocType.payment,
        ),
        label: "Outgoing Payments",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Supplier'), role: Role.supplier),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: CoreLocalizations.of(context)!.accountingLedger,
    route: '/acctLedger',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const LedgerTreeForm(),
        label: "Ledger Tree",
        icon: const Icon(Icons.account_tree),
      ),
      TabItem(
        form: const GlAccountList(),
        label: "Ledger Accnt",
        icon: const Icon(Icons.format_list_bulleted),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("Transaction"),
          sales: true,
          docType: FinDocType.transaction,
        ),
        label: "Ledger Transaction",
        icon: const Icon(Icons.view_list),
      ),
      TabItem(
        form: const LedgerJournalList(key: Key("LedgerJournal")),
        label: "Ledger Journals",
        icon: const Icon(Icons.checklist),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/reportGrey.png",
    selectedImage: "packages/growerp_core/images/report.png",
    title: CoreLocalizations.of(context)!.reports,
    route: '/acctReports',
    tabItems: [
      TabItem(
        form: const RevenueExpenseChart(),
        label: "Revenue/Expense",
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const BalanceSheetForm(),
        label: "Balance Sheet",
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const BalanceSummaryList(),
        label: "Balance Summary",
        icon: const Icon(Icons.list),
      ),
    ],
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: "packages/growerp_core/images/setupGrey.png",
    selectedImage: "packages/growerp_core/images/setup.png",
    title: CoreLocalizations.of(context)!.setUp,
    route: '/acctSetup',
    tabItems: [
      TabItem(
        form: const TimePeriodListForm(),
        label: "Time Periods",
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const ItemTypeList(),
        label: "Item Types",
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const PaymentTypeList(),
        label: "Paymt Types",
        icon: const Icon(Icons.list),
      ),
      TabItem(
        form: const PlanSelectionForm(),
        label: "Plan Selection",
        icon: const Icon(Icons.subscriptions),
      ),
    ],
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: CoreLocalizations.of(context)!.mainDashboard,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
];
