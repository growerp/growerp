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

import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import 'views/admin_db_form.dart' as local;
import 'views/assessment_list_page.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> getMenuOptions(BuildContext context) => [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: CoreLocalizations.of(context)!.main,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: CoreLocalizations.of(context)!.organization,
    route: '/companies',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: ShowCompanyDialog(
          Company(role: Role.company),
          key: const Key('CompanyForm'),
          dialog: false,
        ),
        label: CoreLocalizations.of(context)!.company,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key('Employee'), role: Role.company),
        label: CoreLocalizations.of(context)!.employees,
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const WebsiteDialog(),
        label: CoreLocalizations.of(context)!.website,
        icon: const Icon(Icons.webhook),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: CoreLocalizations.of(context)!.crm,
    route: '/crm',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const ActivityList(ActivityType.todo),
        label: CoreLocalizations.of(context)!.myTodoTasks,
        icon: const Icon(Icons.task),
      ),
      TabItem(
        form: const OpportunityList(),
        label: CoreLocalizations.of(context)!.opportunities,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key('Lead'), role: Role.lead),
        label: CoreLocalizations.of(context)!.leads,
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: CoreLocalizations.of(context)!.customers,
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('Request'),
          sales: false,
          docType: FinDocType.request,
        ),
        label: CoreLocalizations.of(context)!.requests,
        icon: const Icon(Icons.question_answer),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/productsGrey.png',
    selectedImage: 'packages/growerp_core/images/products.png',
    title: CoreLocalizations.of(context)!.catalog,
    route: '/catalog',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const ProductList(),
        label: CoreLocalizations.of(context)!.products,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const AssetList(),
        label: CoreLocalizations.of(context)!.assets,
        icon: const Icon(Icons.money),
      ),
      TabItem(
        form: const CategoryList(),
        label: CoreLocalizations.of(context)!.categories,
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const SubscriptionList(),
        label: CoreLocalizations.of(context)!.subscriptions,
        icon: const Icon(Icons.subscriptions),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: CoreLocalizations.of(context)!.orders,
    route: '/orders',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key('SalesOrder'),
          sales: true,
          docType: FinDocType.order,
        ),
        label: CoreLocalizations.of(context)!.salesOrders,
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: CoreLocalizations.of(context)!.customers,
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('PurchaseOrder'),
          sales: false,
          docType: FinDocType.order,
        ),
        label: CoreLocalizations.of(context)!.purchaseOrders,
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
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: CoreLocalizations.of(context)!.inventory,
    route: '/inventory',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key('ShipmentsOut'),
          sales: true,
          docType: FinDocType.shipment,
        ),
        label: CoreLocalizations.of(context)!.outgoingShipments,
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('ShipmentsIn'),
          sales: false,
          docType: FinDocType.shipment,
        ),
        label: CoreLocalizations.of(context)!.incomingShipments,
        icon: const Icon(Icons.call_received),
      ),
      TabItem(
        form: const AssetList(),
        label: CoreLocalizations.of(context)!.assets,
        icon: const Icon(Icons.money),
      ),
      TabItem(
        form: const LocationList(key: Key('Locations')),
        label: CoreLocalizations.of(context)!.whLocations,
        icon: const Icon(Icons.location_pin),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.accounting,
    route: '/accounting',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/infoGrey.png',
    selectedImage: 'packages/growerp_core/images/info.png',
    title: CoreLocalizations.of(context)!.about,
    route: '/about',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/infoGrey.png',
    selectedImage: 'packages/growerp_core/images/info.png',
    title: 'Assessment',
    route: '/assessment',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const AssessmentFlowWrapper(),
        label: 'Lead Capture',
        icon: const Icon(Icons.assignment),
      ),
      TabItem(
        form: const AssessmentResultsWrapper(),
        label: 'Results',
        icon: const Icon(Icons.assessment),
      ),
    ],
  ),
];

// Function for localized menu options (replaces global variable)
List<MenuOption> menuOptions(BuildContext context) => [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: CoreLocalizations.of(context)!.main,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: CoreLocalizations.of(context)!.organization,
    route: '/companies',
    userGroups: [UserGroup.admin, UserGroup.employee],
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
        form: const UserList(key: Key('Employee'), role: Role.company),
        label: 'Employees',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const WebsiteDialog(),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: CoreLocalizations.of(context)!.crm,
    route: '/crm',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const ActivityList(ActivityType.todo),
        label: 'My To Do, tasks',
        icon: const Icon(Icons.task),
      ),
      TabItem(
        form: const OpportunityList(),
        label: 'Opportunities',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key('Lead'), role: Role.lead),
        label: 'Leads',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('Request'),
          sales: false,
          docType: FinDocType.request,
        ),
        label: 'Requests',
        icon: const Icon(Icons.question_answer),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/productsGrey.png',
    selectedImage: 'packages/growerp_core/images/products.png',
    title: CoreLocalizations.of(context)!.catalog,
    route: '/catalog',
    userGroups: [UserGroup.admin, UserGroup.employee],
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
      TabItem(
        form: const SubscriptionList(),
        label: 'Subscriptions',
        icon: const Icon(Icons.subscriptions),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: CoreLocalizations.of(context)!.orders,
    route: '/orders',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key('SalesOrder'),
          sales: true,
          docType: FinDocType.order,
        ),
        label: 'Sales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('PurchaseOrder'),
          sales: false,
          docType: FinDocType.order,
        ),
        label: 'Purchase orders',
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
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: CoreLocalizations.of(context)!.inventory,
    route: '/inventory',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key('ShipmentsOut'),
          sales: true,
          docType: FinDocType.shipment,
        ),
        label: 'Outgoing shipments',
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('ShipmentsIn'),
          sales: false,
          docType: FinDocType.shipment,
        ),
        label: 'Incoming shipments',
        icon: const Icon(Icons.call_received),
      ),
      TabItem(
        form: const AssetList(),
        label: 'Assets',
        icon: const Icon(Icons.money),
      ),
      TabItem(
        form: const LocationList(key: Key('Locations')),
        label: 'WH Locations',
        icon: const Icon(Icons.location_pin),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.accounting,
    route: '/accounting',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/infoGrey.png',
    selectedImage: 'packages/growerp_core/images/info.png',
    title: CoreLocalizations.of(context)!.about,
    route: '/about',
    userGroups: [UserGroup.admin, UserGroup.employee],
  ),
];
