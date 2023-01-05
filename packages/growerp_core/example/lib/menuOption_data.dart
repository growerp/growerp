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

import 'package:growerp_core/domains/domains.dart';
import 'package:flutter/material.dart';
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
    ],
  ),
  MenuOption(
    image: 'assets/images/companyGrey.png',
    selectedImage: 'assets/images/company.png',
    title: 'Other users',
    route: '/otherusers',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    tabItems: [
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
];
