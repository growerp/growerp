/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:growerp_models/growerp_models.dart';
import '../growerp_user_company.dart';

/// Returns widget mappings for the user_company package
///
/// Usage in app main.dart:
/// ```dart
/// WidgetRegistry.register(getUserCompanyWidgets());
/// ```
Map<String, GrowerpWidgetBuilder> getUserCompanyWidgets() {
  return {
    // User list variants
    'UserList': (args) =>
        UserList(key: getKeyFromArgs(args), role: parseRole(args?['role'])),
    'UserListCustomer': (args) =>
        UserList(key: getKeyFromArgs(args), role: Role.customer),
    'UserListSupplier': (args) =>
        UserList(key: getKeyFromArgs(args), role: Role.supplier),
    'UserListLead': (args) =>
        UserList(key: getKeyFromArgs(args), role: Role.lead),
    'UserListEmployee': (args) =>
        UserList(key: getKeyFromArgs(args), role: Role.company),
    'UserListCompany': (args) =>
        UserList(key: getKeyFromArgs(args), role: Role.company),

    // Company dialogs
    'ShowCompanyDialog': (args) => ShowCompanyDialog(
      Company(role: parseRole(args?['role'])),
      dialog: false,
    ),

    // CompanyUser list variants
    'CompanyUserList': (args) => CompanyUserList(
      key: getKeyFromArgs(args),
      role: parseRole(args?['role']),
    ),
    'CompanyUserListCustomer': (args) =>
        CompanyUserList(key: getKeyFromArgs(args), role: Role.customer),
    'CompanyUserListSupplier': (args) =>
        CompanyUserList(key: getKeyFromArgs(args), role: Role.supplier),
  };
}
