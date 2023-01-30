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
import 'forms/@forms.dart' as local;
import 'package:core/domains/domains.dart';

const MENU_DASHBOARD = 0;
const MENU_COMPANY = 1;
const MENU_CRM = 2;
const MENU_CATALOG = 3;
const MENU_SALES = 4;
const MENU_PURCHASE = 5;
const MENU_ACCOUNTING = 6;
const MENU_ACCTSALES = 1;
const MENU_ACCTPURCHASE = 2;
const MENU_ACCTLEDGER = 3;

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main",
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    child: local.FreelanceDbForm(),
  ),
  MenuOption(
      image: "packages/growerp_core/images/tasksGrey.png",
      selectedImage: "packages/growerp_core/images/tasks.png",
      title: "Tasks",
      route: '/tasks',
      readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
      child: TaskListForm()),
  MenuOption(
    image: "packages/growerp_core/images/crmGrey.png",
    selectedImage: "packages/growerp_core/images/crm.png",
    title: "CRM",
    route: '/crm',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: OpportunityListForm(),
        label: "My Opportunities",
        icon: Icon(Icons.home),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Lead"),
          userGroup: UserGroup.Lead,
        ),
        label: "Leads",
        icon: Icon(Icons.business),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Customer"),
          userGroup: UserGroup.Customer,
        ),
        label: "Customers",
        icon: Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/productsGrey.png",
      selectedImage: "packages/growerp_core/images/products.png",
      title: "Catalog",
      route: '/catalog',
      readGroups: [
        UserGroup.Admin,
        UserGroup.SuperAdmin,
        UserGroup.Employee
      ],
      writeGroups: [
        UserGroup.Admin
      ],
      tabItems: [
        TabItem(
          form: ProductListForm(),
          label: "Products",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: AssetListForm(),
          label: "Assets",
          icon: Icon(Icons.money),
        ),
        TabItem(
          form: CategoryListForm(),
          label: "Categories",
          icon: Icon(Icons.business),
        ),
      ]),
  MenuOption(
    image: 'assets/images/orderGrey.png',
    selectedImage: 'assets/images/order.png',
    title: 'Orders',
    route: '/orders',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin],
    tabItems: [
      TabItem(
        form: const FinDocListForm(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: '\nSales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Customer'),
          userGroup: UserGroup.Customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const FinDocListForm(
            key: Key('PurchaseOrder'), sales: false, docType: FinDocType.order),
        label: '\nPurchase orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Supplier'),
          userGroup: UserGroup.Supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/tasksGrey.png",
      selectedImage: "packages/growerp_core/images/tasks.png",
      title: "Website",
      route: '/website',
      readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
      child: WebsiteForm(
        userGroup: UserGroup.Admin,
      )),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
  MenuOption(
      image: "packages/growerp_core/images/infoGrey.png",
      selectedImage: "packages/growerp_core/images/info.png",
      title: "About",
      route: '/about',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
];
List<MenuOption> acctMenuOptions = [
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "     Acct\nDashBoard",
      route: '/accounting',
      readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin]),
  MenuOption(
      image: "packages/growerp_core/images/orderGrey.png",
      selectedImage: "packages/growerp_core/images/order.png",
      title: " Acct\nSales",
      route: '/acctSales',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
  MenuOption(
      image: "packages/growerp_core/images/supplierGrey.png",
      selectedImage: "packages/growerp_core/images/supplier.png",
      title: "    Acct\nPurchase",
      route: '/acctPurchase',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Ledger",
      route: '/ledger',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
      writeGroups: [UserGroup.Admin]),
  MenuOption(
      image: "packages/growerp_core/images/dashBoardGrey.png",
      selectedImage: "packages/growerp_core/images/dashBoard.png",
      title: "Main",
      route: '/',
      readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin]),
];
