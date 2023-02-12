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
import 'package:core/domains/domains.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: "Main",
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: GanttForm(),
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
        form: const WebsiteForm(
          key: Key('Website'),
          userGroup: UserGroup.employee,
        ),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Admin"),
          userGroup: UserGroup.admin,
        ),
        label: "Admins",
        icon: Icon(Icons.business),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Employee"),
          userGroup: UserGroup.employee,
        ),
        label: "Employees",
        icon: Icon(Icons.school),
      ),
      TabItem(
        form: const CompanyForm(),
        label: "Company Info",
        icon: Icon(Icons.home),
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
        form: AssetListForm(),
        label: "Rooms",
        icon: Icon(Icons.home),
        floatButtonForm: AssetDialog(Asset()),
      ),
      TabItem(
        form: ProductListForm(),
        label: "Room Types",
        icon: Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
      image: "packages/growerp_core/images/reservationGrey.png",
      selectedImage: "packages/growerp_core/images/reservation.png",
      title: "Reservations",
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
          form: FinDocListForm(
              key: Key("SalesOrder"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true),
          label: "Reservations",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: UserListForm(
            key: Key("Customer"),
            userGroup: UserGroup.customer,
          ),
          label: "Customers",
          icon: Icon(Icons.business),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/check-in-outGrey.png",
      selectedImage: "packages/growerp_core/images/check-in-out.png",
      title: "check-In-Out",
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
          form: FinDocListForm(
              key: Key("Check-In"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: 'FinDocCreated'),
          label: "CheckIn",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocListForm(
              key: Key("Check-Out"),
              sales: true,
              docType: FinDocType.order,
              onlyRental: true,
              status: 'FinDocApproved'),
          label: "CheckOut",
          icon: Icon(Icons.home),
        ),
      ]),
  MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: [UserGroup.admin]),
];
