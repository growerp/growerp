// ignore_for_file: depend_on_referenced_packages

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
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'views/forms.dart' as local;
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main",
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const local.FreelanceDbForm(),
  ),
  MenuOption(
      image: "packages/growerp_core/images/tasksGrey.png",
      selectedImage: "packages/growerp_core/images/activities.png",
      title: "Tasks",
      route: '/tasks',
      userGroups: [UserGroup.admin, UserGroup.employee],
      child: const ActivityList(ActivityType.todo)),
  MenuOption(
    image: "packages/growerp_core/images/crmGrey.png",
    selectedImage: "packages/growerp_core/images/crm.png",
    title: "CRM",
    route: '/crm',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const OpportunityList(),
        label: "My Opportunities",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key("Lead"), role: Role.lead),
        label: "Leads",
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserList(
          key: Key("Customer"),
          role: Role.customer,
        ),
        label: "Customers",
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/productsGrey.png",
      selectedImage: "packages/growerp_core/images/products.png",
      title: "Catalog",
      route: '/catalog',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const ProductList(),
          label: "Products",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CategoryList(),
          label: "Categories",
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Orders',
    route: '/orders',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: 'Sales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const FinDocList(
            key: Key('PurchaseOrder'), sales: false, docType: FinDocType.order),
        label: 'Purchase orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key('Supplier'), role: Role.supplier),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/tasksGrey.png",
      selectedImage: "packages/growerp_core/images/activities.png",
      title: "Website",
      route: '/website',
      userGroups: [UserGroup.admin, UserGroup.employee],
      child: const WebsiteDialog()),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      userGroups: [UserGroup.admin]),
  MenuOption(
      image: "packages/growerp_core/images/infoGrey.png",
      selectedImage: "packages/growerp_core/images/info.png",
      title: "About",
      route: '/about',
      userGroups: [UserGroup.admin]),
];
