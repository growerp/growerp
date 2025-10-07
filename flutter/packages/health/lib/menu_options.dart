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
//import 'package:growerp_website/growerp_website.dart';
import 'views/main_menu_form.dart' as local;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> getMenuOptions(BuildContext context) => [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: CoreLocalizations.of(context)!.main,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee, UserGroup.other],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    key: 'dbRequests',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.requests,
    route: '/requests',
    userGroups: [UserGroup.admin, UserGroup.other, UserGroup.employee],
    child: const FinDocList(
      key: Key('Request'),
      sales: false,
      docType: FinDocType.request,
    ),
  ),
  MenuOption(
    key: 'dbCustomers',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.clients,
    route: '/customers',
    userGroups: [UserGroup.employee, UserGroup.admin],
    child: const UserList(key: Key('Customer'), role: Role.customer),
  ),
  MenuOption(
    key: 'dbEmployees',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.staff,
    route: '/employees',
    userGroups: [UserGroup.employee, UserGroup.admin],
    child: const UserList(key: Key('Employee'), role: Role.company),
  ),
  MenuOption(
    key: 'dbCompany',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.organization,
    route: '/company',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: ShowCompanyDialog(Company(), dialog: false),
  ),
  /*  MenuOption(
    key: 'dbWebsite',
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Website',
    route: '/website',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const WebsiteDialog(),
  ),
*/
];

// Function for localized menu options (replaces global variable)
List<MenuOption> menuOptions(BuildContext context) => [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: CoreLocalizations.of(context)!.main,
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee, UserGroup.other],
    child: const local.AdminDbForm(),
  ),
  MenuOption(
    key: 'dbRequests',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.requests,
    route: '/requests',
    userGroups: [UserGroup.admin, UserGroup.other, UserGroup.employee],
    child: const FinDocList(
      key: Key('Request'),
      sales: false,
      docType: FinDocType.request,
    ),
  ),
  MenuOption(
    key: 'dbCustomers',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.clients,
    route: '/customers',
    userGroups: [UserGroup.employee, UserGroup.admin],
    child: const UserList(key: Key('Customer'), role: Role.customer),
  ),
  MenuOption(
    key: 'dbEmployees',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.staff,
    route: '/employees',
    userGroups: [UserGroup.employee, UserGroup.admin],
    child: const UserList(key: Key('Employee'), role: Role.company),
  ),
  MenuOption(
    key: 'dbCompany',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: CoreLocalizations.of(context)!.organization,
    route: '/company',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: ShowCompanyDialog(Company(), dialog: false),
  ),
];
