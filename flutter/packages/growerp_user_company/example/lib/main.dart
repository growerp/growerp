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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');
  String classificationId = GlobalConfiguration().get("classificationId");

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP User & Company Example',
      router: createUserCompanyExampleRouter(),
      extraDelegates: const [UserCompanyLocalizations.delegate],
      extraBlocProviders: getExampleBlocProviders(restClient, classificationId),
    ),
  );
}

List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [...getUserCompanyBlocProviders(restClient, classificationId)];
}

/// Static menu configuration with 3 main tabs (Companies, Users, Companies & Users)
/// Each main tab has sub-tabs for different roles
const userCompanyMenuConfig = MenuConfiguration(
  menuConfigurationId: 'USER_COMPANY_EXAMPLE',
  appId: 'user_company_example',
  name: 'User & Company Example Menu',
  menuOptions: [
    // Main Dashboard
    MenuOption(
      menuOptionId: 'UC_MAIN',
      itemKey: 'UC_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'UserCompanyDashboard',
    ),
    // Companies Tab with sub-tabs
    MenuOption(
      menuOptionId: 'UC_COMPANIES',
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
    MenuOption(
      menuOptionId: 'UC_USERS',
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
    MenuOption(
      menuOptionId: 'UC_COMPANY_USERS',
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
      // Show main company detail screen directly
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
      // Fallback for unknown widget names
      return Center(child: Text('Unknown widget: $widgetName'));
  }
}

/// Creates a static go_router for the user company example app using shared helper
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
      // Company dialog route
      GoRoute(
        path: '/company/:companyId',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'];
          return ShowCompanyDialog(
            Company(partyId: companyId, role: Role.company),
          );
        },
      ),
      // User dialog route
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

        final authenticate = state.authenticate!;
        return DashboardGrid(
          itemCount: 3,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _DashboardCard(
                  title: 'Companies',
                  iconName: 'business',
                  route: '/companies',
                  stats: [
                    'Customers: ${authenticate.stats?.customers ?? 0}',
                    'Leads: ${authenticate.stats?.leads ?? 0}',
                    'Suppliers: ${authenticate.stats?.suppliers ?? 0}',
                  ],
                );
              case 1:
                return _DashboardCard(
                  title: 'Users',
                  iconName: 'people',
                  route: '/users',
                  stats: [
                    'Employees: ${authenticate.company?.employees.length ?? 0}',
                  ],
                );
              default:
                return _DashboardCard(
                  title: 'Companies\n& Users',
                  iconName: 'groups',
                  route: '/companiesUsers',
                  stats: ['Leads: ${authenticate.stats?.leads ?? 0}'],
                );
            }
          },
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;
  final List<String> stats;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 28),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              ...stats.map(
                (stat) => Text(
                  stat,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
