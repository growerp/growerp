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
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

import 'views/accounting_form.dart';

List<MenuOption> acctMenuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: "Accounting\nDashBoard",
    route: '/accounting',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const AccountingForm(),
  ),
  MenuOption(
      image: "packages/growerp_core/images/orderGrey.png",
      selectedImage: "packages/growerp_core/images/order.png",
      title: "Accounting Sales",
      route: '/acctSales',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const FinDocList(
              key: Key("SalesInvoice"),
              sales: true,
              docType: FinDocType.invoice),
          label: "Outgoing Invoices",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocList(
              key: Key("SalesPayment"),
              sales: true,
              docType: FinDocType.payment),
          label: "Incoming Payments",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyList(
            key: Key('Customer'),
            role: Role.customer,
          ),
          label: 'Customers',
          icon: const Icon(Icons.school),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/supplierGrey.png",
      selectedImage: "packages/growerp_core/images/supplier.png",
      title: "Accounting Purch.",
      route: '/acctPurchase',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const FinDocList(
              key: Key("PurchaseInvoice"),
              sales: false,
              docType: FinDocType.invoice),
          label: "Incoming Invoices",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocList(
              key: Key("PurchasePayment"),
              sales: false,
              docType: FinDocType.payment),
          label: "Outgoing Payments",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyList(
            key: Key('Supplier'),
            role: Role.supplier,
          ),
          label: 'Suppliers',
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting Ledger",
      route: '/acctLedger',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const LedgerTreeForm(),
          label: "Ledger Tree",
          icon: const Icon(Icons.account_tree),
        ),
        TabItem(
          form: const GlAccountListForm(),
          label: "Ledger Accnt",
          icon: const Icon(Icons.format_list_bulleted),
        ),
        TabItem(
          form: const FinDocList(
              key: Key("Transaction"),
              sales: true,
              docType: FinDocType.transaction),
          label: "Ledger Transaction",
          icon: const Icon(Icons.view_list),
        ),
        TabItem(
          form: const LedgerJournalListForm(key: Key("LedgerJournal")),
          label: "Ledger Journals",
          icon: const Icon(Icons.checklist),
        ),
      ]),
  MenuOption(
    image: "packages/growerp_core/images/reportGrey.png",
    selectedImage: "packages/growerp_core/images/report.png",
    title: "Reports",
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
    title: "SetUp",
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
    ],
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main dashboard",
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
];
