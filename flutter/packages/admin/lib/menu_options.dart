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
import 'views/admin_db_form.dart' as local;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: 'Company',
    route: '/companies',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    tabItems: [
      TabItem(
        form: ShowCompanyDialog(
          Company(role: Role.company),
          key: const Key('CompanyForm'),
          dialog: false,
        ),
        label: 'Company',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(
          key: Key('Employee'),
          role: Role.company,
        ),
        label: 'Employees',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const WebsiteForm(),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'CRM',
    route: '/crm',
    readGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const OpportunityListForm(),
        label: '        My\nOpportunities',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: '   Lead\nContacs',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('CompanyLead'),
          role: Role.lead,
        ),
        label: '     Lead\nCompanies',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserList(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customer\nContacts',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('CompanyCustomer'),
          role: Role.customer,
        ),
        label: 'Customer\nCompanies',
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
      image: 'packages/growerp_core/images/productsGrey.png',
      selectedImage: 'packages/growerp_core/images/products.png',
      title: 'Catalog',
      route: '/catalog',
      readGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      writeGroups: [
        UserGroup.admin
      ],
      tabItems: [
        TabItem(
          form: const ProductList(),
          label: 'Products',
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const AssetList(),
          label: 'Assets',
          icon: const Icon(Icons.money),
        ),
        TabItem(
          form: const CategoryList(),
          label: 'Categories',
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Orders\n',
    route: '/orders',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    tabItems: [
      TabItem(
        form: const FinDocList(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: 'Sales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyList(
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
        form: const CompanyList(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Inventory',
    route: '/inventory',
    readGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
            key: Key('ShipmentsOut'),
            sales: true,
            docType: FinDocType.shipment),
        label: '\nOutgoing shipments',
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocList(
            key: Key('ShipmentsIn'),
            sales: false,
            docType: FinDocType.shipment),
        label: '\nIncoming shipments',
        icon: const Icon(Icons.call_received),
      ),
      TabItem(
        form: const LocationList(
          key: Key('Locations'),
        ),
        label: '\nWH Locations',
        icon: const Icon(Icons.location_pin),
      ),
    ],
  ),
  MenuOption(
      image: 'packages/growerp_core/images/accountingGrey.png',
      selectedImage: 'packages/growerp_core/images/accounting.png',
      title: 'Accounting',
      route: '/accounting',
      readGroups: [UserGroup.admin]),
  MenuOption(
      image: 'packages/growerp_core/images/infoGrey.png',
      selectedImage: 'packages/growerp_core/images/info.png',
      title: 'About',
      route: '/about',
      readGroups: [UserGroup.admin]),
];
