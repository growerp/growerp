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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import '../findoc/views/views.dart';
import 'views/views.dart';

List<MenuOption> acctMenuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: "Accounting DashBoard",
    route: '/accounting',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    child: const AcctDashBoard(),
  ),
  MenuOption(
      image: "packages/growerp_core/images/orderGrey.png",
      selectedImage: "packages/growerp_core/images/order.png",
      title: "Accounting Sales",
      route: '/acctSales',
      readGroups: [
        UserGroup.Admin,
        UserGroup.SuperAdmin
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
          form: const UserListForm(
            key: Key('Customer'),
            userGroup: UserGroup.Customer,
          ),
          label: '\nCustomers',
          icon: const Icon(Icons.school),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/supplierGrey.png",
      selectedImage: "packages/growerp_core/images/supplier.png",
      title: "Accounting Purchasing",
      route: '/acctPurchase',
      readGroups: [
        UserGroup.Admin,
        UserGroup.SuperAdmin
      ],
      writeGroups: [
        UserGroup.Admin
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
          form: const UserListForm(
            key: Key('Supplier'),
            userGroup: UserGroup.Supplier,
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
        UserGroup.Admin,
        UserGroup.SuperAdmin
      ],
      writeGroups: [
        UserGroup.Admin
      ],
      tabItems: [
        TabItem(
          form: const LedgerTreeForm(),
          label: "Ledger Tree",
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
      ]),
/*  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Reports",
      route: '/reports',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin]),
*/
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main dashboard",
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
  ),
];
