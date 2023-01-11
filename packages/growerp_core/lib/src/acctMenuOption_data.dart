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
import 'domains/domains.dart';

const MENU_ACCOUNTING = 6;
const MENU_ACCTSALES = 1;
const MENU_ACCTPURCHASE = 2;
const MENU_ACCTLEDGER = 3;

List<MenuOption> acctMenuOptions = [
  MenuOption(
    image: "assets/images/accountingGrey.png",
    selectedImage: "assets/images/accounting.png",
    title: "Accounting DashBoard",
    route: '/accounting',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    child: AcctDashBoard(),
  ),
  MenuOption(
      image: "assets/images/orderGrey.png",
      selectedImage: "assets/images/order.png",
      title: "Accounting Sales",
      route: '/acctSales',
      readGroups: [
        UserGroup.Admin,
        UserGroup.SuperAdmin
      ],
      tabItems: [
        TabItem(
          form: FinDocListForm(
              key: Key("SalesInvoice"),
              sales: true,
              docType: FinDocType.invoice),
          label: "\nOutgoing Invoices",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocListForm(
              key: Key("SalesPayment"),
              sales: true,
              docType: FinDocType.payment),
          label: "\nIncoming Payments",
          icon: Icon(Icons.home),
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
      image: "assets/images/supplierGrey.png",
      selectedImage: "assets/images/supplier.png",
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
          form: FinDocListForm(
              key: Key("PurchaseInvoice"),
              sales: false,
              docType: FinDocType.invoice),
          label: "\nIncoming Invoices",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocListForm(
              key: Key("PurchasePayment"),
              sales: false,
              docType: FinDocType.payment),
          label: "\nOutgoing Payments",
          icon: Icon(Icons.home),
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
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
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
          form: LedgerTreeForm(),
          label: "Ledger Tree",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocListForm(
              key: Key("Transaction"),
              sales: true,
              docType: FinDocType.transaction),
          label: "Ledger Transactions",
          icon: Icon(Icons.home),
        ),
      ]),
/*  MenuOption(
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Reports",
      route: '/reports',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin]),
*/
  MenuOption(
    image: "assets/images/dashBoardGrey.png",
    selectedImage: "assets/images/dashBoard.png",
    title: "Main dashboard",
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
  ),
];
