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

    // User Dialog
    'UserDialog': (args) => UserDialog(
      args?['user'] as User? ?? User(), // Empty user = show authenticated user
      dialog: false,
    ),

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

    // System settings
    'SystemSetupDialog': (args) => const SystemSetupDialog(),
  };
}

/// Returns widget metadata with icons for the user_company package
List<WidgetMetadata> getUserCompanyWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'UserList',
      description: 'List of users by role',
      iconName: 'people',
      keywords: ['user', 'person', 'employee', 'customer', 'supplier'],
      builder: (args) =>
          UserList(key: getKeyFromArgs(args), role: parseRole(args?['role'])),
    ),
    WidgetMetadata(
      widgetName: 'UserListCustomer',
      description: 'List of customer users',
      iconName: 'groups',
      keywords: ['customer', 'client', 'buyer'],
      builder: (args) =>
          UserList(key: getKeyFromArgs(args), role: Role.customer),
    ),
    WidgetMetadata(
      widgetName: 'UserListSupplier',
      description: 'List of supplier users',
      iconName: 'factory',
      keywords: ['supplier', 'vendor', 'provider'],
      builder: (args) =>
          UserList(key: getKeyFromArgs(args), role: Role.supplier),
    ),
    WidgetMetadata(
      widgetName: 'UserListLead',
      description: 'List of lead users',
      iconName: 'person_search',
      keywords: ['lead', 'prospect', 'potential'],
      builder: (args) => UserList(key: getKeyFromArgs(args), role: Role.lead),
    ),
    WidgetMetadata(
      widgetName: 'UserListEmployee',
      description: 'List of employee users',
      iconName: 'badge',
      keywords: ['employee', 'staff', 'worker'],
      builder: (args) =>
          UserList(key: getKeyFromArgs(args), role: Role.company),
    ),
    WidgetMetadata(
      widgetName: 'UserListCompany',
      description: 'List of company users',
      iconName: 'business',
      keywords: ['company', 'organization', 'firm'],
      builder: (args) =>
          UserList(key: getKeyFromArgs(args), role: Role.company),
    ),
    WidgetMetadata(
      widgetName: 'UserDialog',
      description: 'User details dialog',
      iconName: 'person',
      keywords: ['user', 'profile', 'details'],
      builder: (args) => UserDialog(
        args?['user'] as User? ??
            User(), // Empty user = show authenticated user
        dialog: false,
      ),
    ),
    WidgetMetadata(
      widgetName: 'ShowCompanyDialog',
      description: 'Company details dialog',
      iconName: 'business',
      keywords: ['company', 'details', 'info'],
      builder: (args) => ShowCompanyDialog(
        Company(role: parseRole(args?['role'])),
        dialog: false,
      ),
    ),
    WidgetMetadata(
      widgetName: 'CompanyUserList',
      description: 'List of companies with their users',
      iconName: 'people',
      keywords: ['company', 'user', 'organization'],
      builder: (args) => CompanyUserList(
        key: getKeyFromArgs(args),
        role: parseRole(args?['role']),
      ),
    ),
    WidgetMetadata(
      widgetName: 'CompanyUserListCustomer',
      description: 'List of customer companies with users',
      iconName: 'groups',
      keywords: ['customer', 'company', 'client'],
      builder: (args) =>
          CompanyUserList(key: getKeyFromArgs(args), role: Role.customer),
    ),
    WidgetMetadata(
      widgetName: 'CompanyUserListSupplier',
      description: 'List of supplier companies with users',
      iconName: 'local_shipping',
      keywords: ['supplier', 'company', 'vendor'],
      builder: (args) =>
          CompanyUserList(key: getKeyFromArgs(args), role: Role.supplier),
    ),
    WidgetMetadata(
      widgetName: 'SystemSetupDialog',
      description: 'System configuration and setup',
      iconName: 'settings',
      keywords: ['settings', 'setup', 'configuration', 'system'],
      builder: (args) => const SystemSetupDialog(),
    ),
  ];
}
