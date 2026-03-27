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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

/// Canonical menu configuration for User & Company example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const userCompanyMenuConfig = MenuConfiguration(
  menuConfigurationId: 'USER_COMPANY_EXAMPLE',
  appId: 'user_company_example',
  name: 'User & Company Example Menu',
  menuItems: [
    // Main Dashboard
    MenuItem(
      menuItemId: 'UC_MAIN',
      itemKey: 'UC_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'UserCompanyDashboard',
    ),
    // Companies Tab with sub-tabs
    MenuItem(
      menuItemId: 'UC_COMPANIES',
      itemKey: 'UC_COMPANIES',
      title: 'Companies',
      route: '/companies',
      iconName: 'business',
      sequenceNum: 20,
      widgetName: 'CompanyList',
      children: [
        MenuItem(
          menuItemId: 'UC_COMP_MAIN',
          title: 'Main Company',
          iconName: 'home_work',
          widgetName: 'CompanyListMain',
          sequenceNum: 1,
        ),
        MenuItem(
          menuItemId: 'UC_COMP_SUPPLIER',
          title: 'Suppliers',
          iconName: 'local_shipping',
          widgetName: 'CompanyListSupplier',
          sequenceNum: 2,
        ),
        MenuItem(
          menuItemId: 'UC_COMP_LEAD',
          title: 'Leads',
          iconName: 'person_search',
          widgetName: 'CompanyListLead',
          sequenceNum: 3,
        ),
        MenuItem(
          menuItemId: 'UC_COMP_CUSTOMER',
          title: 'Customers',
          iconName: 'storefront',
          widgetName: 'CompanyListCustomer',
          sequenceNum: 4,
        ),
        MenuItem(
          menuItemId: 'UC_COMP_ALL',
          title: 'All',
          iconName: 'apartment',
          widgetName: 'CompanyList',
          sequenceNum: 5,
        ),
      ],
    ),
    // Users Tab with sub-tabs
    MenuItem(
      menuItemId: 'UC_USERS',
      itemKey: 'UC_USERS',
      title: 'Users',
      route: '/users',
      iconName: 'people',
      sequenceNum: 30,
      widgetName: 'UserList',
      children: [
        MenuItem(
          menuItemId: 'UC_USER_EMPLOYEE',
          title: 'Employees',
          iconName: 'badge',
          widgetName: 'UserListEmployee',
          sequenceNum: 1,
        ),
        MenuItem(
          menuItemId: 'UC_USER_SUPPLIER',
          title: 'Supplier Users',
          iconName: 'local_shipping',
          widgetName: 'UserListSupplier',
          sequenceNum: 2,
        ),
        MenuItem(
          menuItemId: 'UC_USER_LEAD',
          title: 'Lead Users',
          iconName: 'person_search',
          widgetName: 'UserListLead',
          sequenceNum: 3,
        ),
        MenuItem(
          menuItemId: 'UC_USER_CUSTOMER',
          title: 'Customer Users',
          iconName: 'storefront',
          widgetName: 'UserListCustomer',
          sequenceNum: 4,
        ),
        MenuItem(
          menuItemId: 'UC_USER_ALL',
          title: 'All',
          iconName: 'groups',
          widgetName: 'UserList',
          sequenceNum: 5,
        ),
      ],
    ),
    // Companies & Users Tab with sub-tabs
    MenuItem(
      menuItemId: 'UC_COMPANY_USERS',
      itemKey: 'UC_COMPANY_USERS',
      title: 'Companies & Users',
      route: '/companiesUsers',
      iconName: 'groups',
      sequenceNum: 40,
      widgetName: 'CompanyUserList',
      children: [
        MenuItem(
          menuItemId: 'UC_CU_SUPPLIER',
          title: 'Supplier\nComp & Users',
          iconName: 'local_shipping',
          widgetName: 'CompanyUserListSupplier',
          sequenceNum: 1,
        ),
        MenuItem(
          menuItemId: 'UC_CU_LEAD',
          title: 'Lead\nComp & Users',
          iconName: 'person_search',
          widgetName: 'CompanyUserListLead',
          sequenceNum: 2,
        ),
        MenuItem(
          menuItemId: 'UC_CU_CUSTOMER',
          title: 'Customer\nComp & Users',
          iconName: 'storefront',
          widgetName: 'CompanyUserListCustomer',
          sequenceNum: 3,
        ),
        MenuItem(
          menuItemId: 'UC_CU_ALL',
          title: 'All\nComp & Users',
          iconName: 'groups',
          widgetName: 'CompanyUserList',
          sequenceNum: 4,
        ),
      ],
    ),
  ],
);

/// Widget loader for the tabbed interface
Widget loadTabWidget(String widgetName, Map<String, dynamic> args) {
  switch (widgetName) {
    // Company tab widgets
    case 'CompanyListMain':
      return ShowCompanyDialog(
        Company(role: Role.company),
        key: const Key('CompanyListMain'),
        dialog: false,
      );
    case 'CompanyListSupplier':
      return const CompanyList(
        key: Key('CompanyListSupplier'),
        role: Role.supplier,
      );
    case 'CompanyListLead':
      return const CompanyList(key: Key('CompanyListLead'), role: Role.lead);
    case 'CompanyListCustomer':
      return const CompanyList(
        key: Key('CompanyListCustomer'),
        role: Role.customer,
      );
    case 'CompanyList':
      return const CompanyList(key: Key('CompanyList'), role: Role.unknown);
    // User tab widgets
    case 'UserListEmployee':
      return const UserList(key: Key('UserListEmployee'), role: Role.company);
    case 'UserListSupplier':
      return const UserList(key: Key('UserListSupplier'), role: Role.supplier);
    case 'UserListLead':
      return const UserList(key: Key('UserListLead'), role: Role.lead);
    case 'UserListCustomer':
      return const UserList(key: Key('UserListCustomer'), role: Role.customer);
    case 'UserList':
      return const UserList(key: Key('UserList'), role: Role.unknown);
    // CompanyUser tab widgets
    case 'CompanyUserListSupplier':
      return const CompanyUserList(
        key: Key('CompanyUserListSupplier'),
        role: Role.supplier,
      );
    case 'CompanyUserListLead':
      return const CompanyUserList(
        key: Key('CompanyUserListLead'),
        role: Role.lead,
      );
    case 'CompanyUserListCustomer':
      return const CompanyUserList(
        key: Key('CompanyUserListCustomer'),
        role: Role.customer,
      );
    case 'CompanyUserList':
      return const CompanyUserList(
        key: Key('CompanyUserList'),
        role: Role.unknown,
      );
    default:
      return Center(child: Text('Unknown widget: $widgetName'));
  }
}

/// Creates a static go_router for the user company example app.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createUserCompanyExampleRouter() {
  return createStaticAppRouter(
    menuConfig: userCompanyMenuConfig,
    appTitle: 'GrowERP User & Company Example',
    dashboard: const UserCompanyDashboard(),
    tabWidgetLoader: loadTabWidget,
    widgetBuilder: (route) => switch (route) {
      '/companies' => ShowCompanyDialog(
        Company(role: Role.company),
        key: const Key('CompanyListMain'),
        dialog: false,
      ),
      '/users' => const UserList(
        key: Key('UserListEmployee'),
        role: Role.company,
      ),
      '/companiesUsers' => const CompanyUserList(
        key: Key('CompanyUserListSupplier'),
        role: Role.supplier,
      ),
      _ => const UserCompanyDashboard(),
    },
    additionalRoutes: [
      GoRoute(
        path: '/company/:companyId',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'];
          return ShowCompanyDialog(
            Company(partyId: companyId, role: Role.company),
          );
        },
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'];
          return UserDialog(User(partyId: userId));
        },
      ),
    ],
  );
}

/// Simple dashboard for user company example
class UserCompanyDashboard extends StatelessWidget {
  const UserCompanyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        return DashboardGrid(
          items: const [
            MenuItem(
              menuItemId: 'companies',
              title: 'Companies',
              iconName: 'business',
              route: '/companies',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'users',
              title: 'Users',
              iconName: 'people',
              route: '/users',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'companies_users',
              title: 'Companies & Users',
              iconName: 'groups',
              route: '/companiesUsers',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
