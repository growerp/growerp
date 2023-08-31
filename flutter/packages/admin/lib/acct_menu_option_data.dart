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

import 'forms/accounting_form.dart';

List<MenuOption> acctMenuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: "Accounting\nDashBoard",
    route: '/accounting',
    readGroups: [UserGroup.admin, UserGroup.employee],
    child: const AccountingForm(),
  ),
  MenuOption(
      image: "packages/growerp_core/images/orderGrey.png",
      selectedImage: "packages/growerp_core/images/order.png",
      title: "Accounting Sales",
      route: '/acctSales',
      readGroups: [
        UserGroup.admin,
      ],
      tabItems: [
        TabItem(
          form: const FinDocListForm(
              key: Key("SalesInvoice"),
              sales: true,
              docType: FinDocType.invoice),
          label: "\nOutgoing Invoices",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocListForm(
              key: Key("SalesPayment"),
              sales: true,
              docType: FinDocType.payment),
          label: "\nIncoming Payments",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyListForm(
            key: Key('Customer'),
            role: Role.customer,
          ),
          label: '\nCustomers',
          icon: const Icon(Icons.school),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/supplierGrey.png",
      selectedImage: "packages/growerp_core/images/supplier.png",
      title: "Accounting Purch.",
      route: '/acctPurchase',
      readGroups: [
        UserGroup.admin,
      ],
      writeGroups: [
        UserGroup.admin
      ],
      tabItems: [
        TabItem(
          form: const FinDocListForm(
              key: Key("PurchaseInvoice"),
              sales: false,
              docType: FinDocType.invoice),
          label: "\nIncoming Invoices",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocListForm(
              key: Key("PurchasePayment"),
              sales: false,
              docType: FinDocType.payment),
          label: "\nOutgoing Payments",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyListForm(
            key: Key('Supplier'),
            role: Role.supplier,
          ),
          label: '\nSuppliers',
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting Ledger\n",
      route: '/acctLedger',
      readGroups: [
        UserGroup.admin,
      ],
      writeGroups: [
        UserGroup.admin
      ],
      tabItems: [
        TabItem(
          form: const LedgerTreeForm(),
          label: "Ledger Tree",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const GlAccountListForm(),
          label: "Ledger Accounts",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocListForm(
              key: Key("Transaction"),
              sales: true,
              docType: FinDocType.transaction),
          label: "Ledger Transactions",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const LedgerJournalListForm(key: Key("LedgerJournal")),
          label: "Ledger Journals",
          icon: const Icon(Icons.home),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/reportGrey.png",
      selectedImage: "packages/growerp_core/images/report.png",
      title: "Reports",
      route: '/acctReports',
      tabItems: [
        TabItem(
          form: const BalanceSheetForm(),
          label: "\nBalance Sheet",
          icon: const Icon(Icons.list),
        ),
        TabItem(
          form: const BalanceSummaryListForm(),
          label: "\nBalance Summary",
          icon: const Icon(Icons.list),
        ),
      ],
      readGroups: [
        UserGroup.admin
      ],
      writeGroups: [
        UserGroup.admin
      ]),
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main dashboard",
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
  ),
];
