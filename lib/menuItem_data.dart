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

import 'package:core/forms/@forms.dart';
import 'package:flutter/material.dart';
import 'package:models/@models.dart';
import 'forms/gantt_form.dart';

List<MenuItem> menuItems = [
  MenuItem(
    image: "assets/images/dashBoardGrey.png",
    selectedImage: "assets/images/dashBoard.png",
    title: "Main",
    route: '/',
    readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
    writeGroups: ["GROWERP_M_ADMIN"],
    child: GanttForm(),
    floatButtonForm: ReservationDialog(
      formArguments: FormArguments(object: FinDoc(items: [])),
    ),
  ),
  MenuItem(
    image: "assets/images/companyGrey.png",
    selectedImage: "assets/images/company.png",
    title: "Hotel",
    route: '/company',
    readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
    writeGroups: ["GROWERP_M_ADMIN"],
    tabItems: [
      TabItem(
        form: CompanyInfoForm(FormArguments()),
        label: "Company Info",
        icon: Icon(Icons.home),
      ),
      TabItem(
        form: UsersForm(
          key: ValueKey("GROWERP_M_ADMIN"),
          userGroupId: "GROWERP_M_ADMIN",
        ),
        label: "Admins",
        icon: Icon(Icons.business),
        floatButtonForm: UserDialog(
            formArguments:
                FormArguments(object: User(userGroupId: "GROWERP_M_ADMIN"))),
      ),
      TabItem(
        form: UsersForm(
          key: ValueKey("GROWERP_M_EMPLOYEE"),
          userGroupId: "GROWERP_M_EMPLOYEE",
        ),
        label: "Employees",
        icon: Icon(Icons.school),
        floatButtonForm: UserDialog(
            formArguments:
                FormArguments(object: User(userGroupId: "GROWERP_M_EMPLOYEE"))),
      ),
    ],
  ),
  MenuItem(
    image: "assets/images/single-bedGrey.png",
    selectedImage: "assets/images/single-bed.png",
    title: "Rooms",
    route: '/rooms',
    readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
    tabItems: [
      TabItem(
        form: AssetsForm(),
        label: "Rooms",
        icon: Icon(Icons.home),
        floatButtonForm: AssetDialog(formArguments: FormArguments()),
      ),
      TabItem(
        form: ProductsForm(),
        label: "Room Types",
        icon: Icon(Icons.home),
        floatButtonForm:
            ProductDialog(formArguments: FormArguments(object: Product())),
      ),
    ],
  ),
  MenuItem(
      image: "assets/images/reservationGrey.png",
      selectedImage: "assets/images/reservation.png",
      title: "Reservations",
      route: '/reservations',
      readGroups: [
        "GROWERP_M_ADMIN",
        "GROWERP_M_EMPLOYEE"
      ],
      writeGroups: [
        "GROWERP_M_ADMIN"
      ],
      tabItems: [
        TabItem(
          form: FinDocsForm(sales: true, docType: 'order', onlyRental: true),
          label: "Reservations",
          icon: Icon(Icons.home),
          floatButtonForm: ReservationDialog(
            formArguments: FormArguments(object: FinDoc(items: [])),
          ),
        ),
        TabItem(
          form: UsersForm(
            key: ValueKey("GROWERP_M_CUSTOMER"),
            userGroupId: "GROWERP_M_CUSTOMER",
          ),
          label: "Customers",
          icon: Icon(Icons.business),
          floatButtonForm: UserDialog(
              formArguments: FormArguments(
                  object: User(userGroupId: "GROWERP_M_CUSTOMER"))),
        ),
      ]),
  MenuItem(
      image: "assets/images/check-in-outGrey.png",
      selectedImage: "assets/images/check-in-out.png",
      title: "check-In-out",
      route: '/checkInOut',
      readGroups: [
        "GROWERP_M_ADMIN",
        "GROWERP_M_EMPLOYEE"
      ],
      writeGroups: [
        "GROWERP_M_ADMIN"
      ],
      tabItems: [
        TabItem(
          form: FinDocsForm(
              sales: true, docType: 'order', rentalFromDate: DateTime.now()),
          label: "CheckIn",
          icon: Icon(Icons.home),
        ),
        TabItem(
          form: FinDocsForm(
              sales: true, docType: 'order', rentalThruDate: DateTime.now()),
          label: "CheckOut",
          icon: Icon(Icons.home),
        ),
      ]),
  MenuItem(
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: ["GROWERP_M_ADMIN"]),
];
