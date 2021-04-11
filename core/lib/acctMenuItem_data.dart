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
import 'package:models/@models.dart';

import 'forms/@forms.dart';

const MENU_ACCOUNTING = 6;
const MENU_ACCTSALES = 1;
const MENU_ACCTPURCHASE = 2;
const MENU_ACCTLEDGER = 3;

List<MenuItem> acctMenuItems = [
  MenuItem(
    image: "assets/images/accountingGrey.png",
    selectedImage: "assets/images/accounting.png",
    title: "     Acct\nDashBoard",
    route: '/accounting',
    readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
    child: AcctDashBoard(),
  ),
  MenuItem(
      image: "assets/images/orderGrey.png",
      selectedImage: "assets/images/order.png",
      title: " Acct\nSales",
      route: '/acctSales',
      readGroups: [
        "GROWERP_M_ADMIN"
      ],
      tabItems: [
        TabItem(
          form: FinDocsForm(sales: true, docType: 'invoice'),
          label: "Sales invoices",
          icon: Icon(Icons.home),
          floatButtonRoute: "/finDoc",
          floatButtonArgs: FormArguments(
              object: FinDoc(sales: true, docType: 'invoice', items: []),
              menuIndex: MENU_ACCTSALES),
        ),
        TabItem(
          form: FinDocsForm(sales: true, docType: 'payment'),
          label: "Sales payments(Receipts)",
          icon: Icon(Icons.home),
          floatButtonRoute: "/finDoc",
          floatButtonArgs: FormArguments(
              object: FinDoc(sales: true, docType: 'payment', items: []),
              menuIndex: MENU_ACCTSALES),
        ),
      ]),
  MenuItem(
      image: "assets/images/supplierGrey.png",
      selectedImage: "assets/images/supplier.png",
      title: "    Acct\nPurchase",
      route: '/acctPurchase',
      readGroups: [
        "GROWERP_M_ADMIN"
      ],
      writeGroups: [
        "GROWERP_M_ADMIN"
      ],
      tabItems: [
        TabItem(
          form: FinDocsForm(sales: false, docType: 'invoice'),
          label: "Purchase invoices",
          icon: Icon(Icons.home),
          floatButtonRoute: "/finDoc",
          floatButtonArgs: FormArguments(
              object: FinDoc(sales: false, docType: 'invoice', items: []),
              menuIndex: MENU_ACCTPURCHASE),
        ),
        TabItem(
          form: FinDocsForm(sales: false, docType: 'payment'),
          label: "Puchase payments",
          icon: Icon(Icons.home),
          floatButtonRoute: "/finDoc",
          floatButtonArgs: FormArguments(
              object: FinDoc(sales: false, docType: 'payment', items: []),
              menuIndex: MENU_ACCTPURCHASE),
        ),
      ]),
  MenuItem(
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Ledger",
      route: '/ledger',
      readGroups: [
        "GROWERP_M_ADMIN"
      ],
      writeGroups: [
        "GROWERP_M_ADMIN"
      ],
      tabItems: [
        TabItem(
          form: LedgerTreeForm(),
          label: "Ledger Tree",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocsForm(docType: 'transaction'),
          label: "Transactions",
          icon: Icon(Icons.home),
          floatButtonRoute: "/finDoc",
          floatButtonArgs: FormArguments(
              object: FinDoc(sales: true, docType: 'transaction', items: []),
              menuIndex: MENU_ACCTLEDGER),
        ),
      ]),
/*  MenuItem(
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Reports",
      route: '/reports',
      readGroups: ["GROWERP_M_ADMIN"],
      writeGroups: ["GROWERP_M_ADMIN"]),
*/
  MenuItem(
      image: "assets/images/dashBoardGrey.png",
      selectedImage: "assets/images/dashBoard.png",
      title: "Main",
      route: '/',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
];
