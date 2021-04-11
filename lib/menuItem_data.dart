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

List<MenuItem> menuItems = [
  MenuItem(
      image: "assets/images/dashBoardGrey.png",
      selectedImage: "assets/images/dashBoard.png",
      title: "Main",
      route: '/',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      child: GanttForm()),
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
        floatButtonForm: UserForm(
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
        floatButtonForm: UserForm(
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
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
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
          form: FinDocsForm(sales: true, docType: 'order'),
          label: "Sales orders",
          icon: Icon(Icons.home),
          floatButtonForm: FinDocForm(
            formArguments: FormArguments(
                object: FinDoc(sales: true, docType: 'order', items: [])),
          ),
        ),
        TabItem(
          form: UsersForm(
            key: ValueKey("GROWERP_M_CUSTOMER"),
            userGroupId: "GROWERP_M_CUSTOMER",
          ),
          label: "Customers",
          icon: Icon(Icons.business),
          floatButtonForm: UserForm(
              formArguments: FormArguments(
                  object: User(userGroupId: "GROWERP_M_CUSTOMER"))),
        ),
      ]),
  MenuItem(
      image: "assets/images/check-inGrey.png",
      selectedImage: "assets/images/check-in.png",
      title: "check-In",
      route: '/checkIn',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      image: "assets/images/check-outGrey.png",
      selectedImage: "assets/images/check-out.png",
      title: "Check-Out",
      route: '/',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: ["GROWERP_M_ADMIN"]),
];
