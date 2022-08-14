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
    image: "assets/images/dashBoardGrey.png",
    selectedImage: "assets/images/dashBoard.png",
    title: "Main",
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee],
    writeGroups: [UserGroup.Admin],
    child: GanttForm(),
  ),
  MenuOption(
    image: "assets/images/companyGrey.png",
    selectedImage: "assets/images/company.png",
    title: "Hotel",
    route: '/company',
    readGroups: [UserGroup.Admin, UserGroup.Employee],
    writeGroups: [UserGroup.Admin],
    tabItems: [
      TabItem(
        form: const WebsiteForm(
          key: Key('Website'),
          userGroup: UserGroup.Employee,
        ),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Admin"),
          userGroup: UserGroup.Admin,
        ),
        label: "Admins",
        icon: Icon(Icons.business),
      ),
      TabItem(
        form: UserListForm(
          key: Key("Employee"),
          userGroup: UserGroup.Employee,
        ),
        label: "Employees",
        icon: Icon(Icons.school),
      ),
      TabItem(
        form: CompanyForm(FormArguments()),
        label: "Company Info",
        icon: Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
    image: "assets/images/single-bedGrey.png",
    selectedImage: "assets/images/single-bed.png",
    title: "Rooms",
    route: '/catalog',
    readGroups: [UserGroup.Admin, UserGroup.Employee],
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
      image: "assets/images/reservationGrey.png",
      selectedImage: "assets/images/reservation.png",
      title: "Reservations",
      route: '/sales',
      readGroups: [
        UserGroup.Admin,
        UserGroup.Employee
      ],
      writeGroups: [
        UserGroup.Admin
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
            userGroup: UserGroup.Customer,
          ),
          label: "Customers",
          icon: Icon(Icons.business),
        ),
      ]),
  MenuOption(
      image: "assets/images/check-in-outGrey.png",
      selectedImage: "assets/images/check-in-out.png",
      title: "check-In-Out",
      route: '/checkInOut',
      readGroups: [
        UserGroup.Admin,
        UserGroup.Employee
      ],
      writeGroups: [
        UserGroup.Admin
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
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: [UserGroup.Admin]),
];
