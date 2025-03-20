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
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';

import 'views/gantt_form.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main",
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const GanttForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/companyGrey.png",
    selectedImage: "packages/growerp_core/images/company.png",
    title: "My Hotel",
    route: '/myHotel',
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
    image: "packages/growerp_core/images/single-bedGrey.png",
    selectedImage: "packages/growerp_core/images/single-bed.png",
    title: "Rooms",
    route: '/rooms',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const AssetList(),
        label: "Rooms",
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const ProductList(),
        label: "Room Types",
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/reservationGrey.png",
      selectedImage: "packages/growerp_core/images/reservation.png",
      title: "Reservations",
      route: '/reservations',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const FinDocList(
              key: Key("SalesOrder"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true),
          label: "Reservations",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyUserList(
            key: Key('Customer'),
            role: Role.customer,
          ),
          label: 'Customers',
          icon: const Icon(Icons.school),
        ),
        TabItem(
          form: const FinDocList(
              key: Key('PurchaseOrder'),
              sales: false,
              docType: FinDocType.order),
          label: 'Purchase orders',
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyUserList(
            key: Key('Supplier'),
            role: Role.supplier,
          ),
          label: 'Suppliers',
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/check-in-outGrey.png",
      selectedImage: "packages/growerp_core/images/check-in-out.png",
      title: "In-Out",
      route: '/checkInOut',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      tabItems: [
        TabItem(
          form: const FinDocList(
              key: Key("Check-In"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: FinDocStatusVal.created),
          label: "CheckIn",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocList(
              key: Key("Check-Out"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: FinDocStatusVal.approved),
          label: "CheckOut",
          icon: const Icon(Icons.home),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      userGroups: [UserGroup.admin]),
];
