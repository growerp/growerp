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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_website/growerp_website.dart';
import 'forms/@forms.dart' as local;

List<MenuOption> menuOptions = [
  MenuOption(
    image: 'assets/images/dashBoardGrey.png',
    selectedImage: 'assets/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    child: local.AdminDbForm(),
  ),
  MenuOption(
    image: 'assets/images/companyGrey.png',
    selectedImage: 'assets/images/company.png',
    title: 'Company',
    route: '/company',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: CompanyForm(FormArguments()),
        label: 'Company Info',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Admin'),
          userGroup: UserGroup.Admin,
        ),
        label: 'Admins',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Employee'),
          userGroup: UserGroup.Employee,
        ),
        label: 'Employees',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const WebsiteForm(key: Key('Website')),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
    ],
  ),
  MenuOption(
    image: 'assets/images/crmGrey.png',
    selectedImage: 'assets/images/crm.png',
    title: 'CRM',
    route: '/crm',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: const OpportunityListForm(),
        label: 'My Opportunities',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Lead'),
          userGroup: UserGroup.Lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Customer'),
          userGroup: UserGroup.Customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
      image: 'assets/images/productsGrey.png',
      selectedImage: 'assets/images/products.png',
      title: 'Catalog',
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
          form: const ProductListForm(),
          label: 'Products',
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const AssetListForm(),
          label: 'Assets',
          icon: const Icon(Icons.money),
        ),
        TabItem(
          form: const CategoryListForm(),
          label: 'Categories',
          icon: const Icon(Icons.business),
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
    image: 'assets/images/supplierGrey.png',
    selectedImage: 'assets/images/supplier.png',
    title: 'Inventory',
    route: '/inventory',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: const FinDocListForm(
            key: Key('ShipmentsOut'),
            sales: true,
            docType: FinDocType.shipment),
        label: '\nOutgoing shipments',
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocListForm(
            key: Key('ShipmentsIn'),
            sales: false,
            docType: FinDocType.shipment),
        label: '\nIncoming shipments',
        icon: const Icon(Icons.call_received),
      ),
      TabItem(
        form: LocationListForm(),
        label: '\nWH Locations',
        icon: const Icon(Icons.location_pin),
      ),
    ],
  ),
  MenuOption(
      image: 'assets/images/accountingGrey.png',
      selectedImage: 'assets/images/accounting.png',
      title: 'Accounting',
      route: '/accounting',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
  MenuOption(
      image: 'packages/growerp_core/images/infoGrey.png',
      selectedImage: 'packages/growerp_core/images/info.png',
      title: 'About',
      route: '/about',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
];
