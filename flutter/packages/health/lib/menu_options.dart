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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_website/growerp_website.dart';
import 'views/main_menu_form.dart' as local;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee, UserGroup.other],
    writeGroups: [UserGroup.admin],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Requests',
    route: '/requests',
    writeGroups: [UserGroup.admin],
    myGroups: [UserGroup.other, UserGroup.employee],
    child: const FinDocList(
        key: Key('Request'), sales: false, docType: FinDocType.request),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Patients',
    route: '/customers',
    readGroups: [UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const UserList(
      key: Key('Customer'),
      role: Role.customer,
    ),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Staff',
    route: '/employees',
    readGroups: [UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const UserList(
      key: Key('Employee'),
      role: Role.company,
    ),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Hospital',
    route: '/company',
    writeGroups: [UserGroup.admin],
    readGroups: [UserGroup.employee, UserGroup.other],
    child: ShowCompanyDialog(
      Company(),
      dialog: false,
    ),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Website',
    route: '/website',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const WebsiteForm(),
  ),
];
