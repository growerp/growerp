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

import 'package:flutter_bloc/flutter_bloc.dart';
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

    // User Dialog. A typed User → as-is. Chat/AI create (prefill fields or the
    // _aiPrefill marker) → render the inner UserDialogStateFull directly so a NEW
    // (prefilled) user form is shown — the UserDialog wrapper would otherwise
    // discard a party-less user and load the authenticated user ("my profile").
    'UserDialog': (args) {
      final typed = args?['user'] as User?;
      if (typed != null) return UserDialog(typed, dialog: true);
      final prefilled = entityFromArgs<User>(args, User.fromJson);
      if (prefilled != null || isAiPrefill(args)) {
        return UserDialogStateFull(
          user: (prefilled ?? User()).copyWith(role: parseRole(args?['role'])),
          dialog: true,
        );
      }
      return UserDialog(User(role: parseRole(args?['role'])), dialog: true);
    },

    // Company dialogs — typed Company, or prefill field values, else empty.
    'ShowCompanyDialog': (args) => ShowCompanyDialog(
      args?['company'] as Company? ??
          entityFromArgs<Company>(
              args, (j) => Company.fromJson(j).copyWith(role: parseRole(args?['role']))) ??
          Company(role: parseRole(args?['role'])),
      dialog: true,
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

    // Company list (main/owner companies)
    'CompanyListMainOnly': (args) =>
        const CompanyList(role: null, mainOnly: true),

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
      description: 'Create or edit a user. Pass partyId to edit an existing '
          'user; omit it to create a new one (optional role: customer/supplier/'
          'lead/employee).',
      iconName: 'person',
      keywords: ['add user', 'new user', 'create user', 'edit user', 'open user'],
      parameters: {
        'partyId': 'open this user for editing; omit to create new',
        'role': 'customer | supplier | lead | employee (for create)',
        'firstName': 'first name (prefill for create)',
        'lastName': 'last name (prefill for create)',
        'email': 'email address (prefill for create)',
        'telephoneNr': 'phone number (prefill for create)',
      },
      builder: (args) {
        final id = (args?['partyId'] ?? args?['userPartyId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) {
          final prefilled = entityFromArgs<User>(args, User.fromJson);
          // CREATE only when there's an explicit create signal (AI prefill marker
          // or supplied field values). Render the inner form directly so a NEW
          // (blank/prefilled) user is shown, not the authenticated user.
          if (prefilled != null || isAiPrefill(args)) {
            final user = (prefilled ?? User()).copyWith(role: parseRole(args?['role']));
            return UserDialogStateFull(user: user, dialog: true);
          }
          // No create signal → show the current/authenticated user ("my profile").
          return UserDialog(User(role: parseRole(args?['role'])), dialog: true);
        }
        return AsyncRecordDialog<User>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getUser(partyId: id, limit: 1);
            return r.users.isNotEmpty ? r.users.first : null;
          },
          onLoaded: (u) => UserDialog(u, dialog: true),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'ShowCompanyDialog',
      description: 'Show, create or edit a company. Omit partyId to show the '
          "owner's main company; pass a partyId to edit an existing company; "
          "pass partyId='_NEW_' to create a new one.",
      iconName: 'business',
      keywords: ['add company', 'new company', 'create company', 'edit company', 'open company'],
      parameters: {
        'partyId': "company to edit; '_NEW_' to create; omit for the main company",
        'name': 'company name (prefill for create)',
        'email': 'company email (prefill for create)',
      },
      builder: (args) {
        // ShowCompanyDialog resolves the company itself:
        //   null partyId  -> owner's main company (from authenticate)
        //   '_NEW_'       -> blank create form
        //   other partyId -> fetched and edited
        final id = (args?['partyId'] ?? args?['companyPartyId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) {
          // Show/create — prefill from any supplied field values.
          final prefilled = entityFromArgs<Company>(args, Company.fromJson);
          return ShowCompanyDialog(
            (prefilled ?? Company()).copyWith(role: parseRole(args?['role'])),
            dialog: true,
          );
        }
        return ShowCompanyDialog(Company(partyId: id), dialog: true);
      },
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
      widgetName: 'CompanyListMainOnly',
      description: 'List of all installed owner companies',
      iconName: 'business',
      keywords: ['owner', 'company', 'installed', 'tenant'],
      builder: (args) => const CompanyList(role: null, mainOnly: true),
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
