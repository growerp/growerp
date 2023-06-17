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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_catalog/growerp_catalog.dart';

import 'forms/gantt_form.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main",
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const GanttForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/companyGrey.png",
    selectedImage: "packages/growerp_core/images/company.png",
    title: "Hotel",
    route: '/company',
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
        form: const UserListForm(
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
    route: '/catalog',
    readGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const AssetListForm(),
        label: "Rooms",
        icon: const Icon(Icons.home),
        floatButtonForm: AssetDialog(Asset()),
      ),
      TabItem(
        form: const ProductListForm(),
        label: "Room Types",
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/reservationGrey.png",
      selectedImage: "packages/growerp_core/images/reservation.png",
      title: "Reservations\n",
      route: '/sales',
      readGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      writeGroups: [
        UserGroup.admin
      ],
      tabItems: [
        TabItem(
          form: const FinDocListForm(
              key: Key("SalesOrder"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true),
          label: "Reservations",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const UserListForm(
            key: Key('Customer'),
            role: Role.customer,
          ),
          label: 'Customer Contacts',
          icon: const Icon(Icons.school),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/check-in-outGrey.png",
      selectedImage: "packages/growerp_core/images/check-in-out.png",
      title: "In-Out",
      route: '/checkInOut',
      readGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      writeGroups: [
        UserGroup.admin
      ],
      tabItems: [
        TabItem(
          form: const FinDocListForm(
              key: Key("Check-In"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: 'FinDocCreated'),
          label: "CheckIn",
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocListForm(
              key: Key("Check-Out"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: 'FinDocApproved'),
          label: "CheckOut",
          icon: const Icon(Icons.home),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: [UserGroup.admin]),
];
