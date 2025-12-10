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

/// Static menu configuration
const userCompanyMenuConfig = MenuConfiguration(
  menuConfigurationId: 'USER_COMPANY_EXAMPLE',
  appId: 'user_company_example',
  name: 'User & Company Example Menu',
  menuOptions: [
    MenuOption(
      itemKey: 'UC_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'UserCompanyDashboard',
    ),
    MenuOption(
      itemKey: 'UC_COMPANIES',
      title: 'Companies',
      route: '/companies',
      iconName: 'business',
      sequenceNum: 20,
      widgetName: 'CompanyList',
    ),
    MenuOption(
      itemKey: 'UC_USERS',
      title: 'Users',
      route: '/users',
      iconName: 'people',
      sequenceNum: 30,
      widgetName: 'UserList',
    ),
    MenuOption(
      itemKey: 'UC_COMPANY_USERS',
      title: 'Companies & Users',
      route: '/companiesUsers',
      iconName: 'groups',
      sequenceNum: 40,
      widgetName: 'CompanyUserList',
    ),
  ],
);

/// Creates a static go_router for the user company example app using shared helper
GoRouter createUserCompanyExampleRouter() {
  return createStaticAppRouter(
    menuConfig: userCompanyMenuConfig,
    appTitle: 'GrowERP User & Company Example',
    dashboard: const UserCompanyDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/companies' => ShowCompanyDialog(
        Company(role: Role.company),
        key: const Key('CompanyForm'),
        dialog: false,
      ),
      '/users' => const UserList(key: Key('Employee'), role: Role.company),
      '/companiesUsers' => const CompanyUserList(
        key: Key('Lead'),
        role: Role.lead,
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
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _DashboardCard(
                    title: 'Companies',
                    iconName: 'business',
                    route: '/companies',
                    stats:
                        'Customers: ${authenticate.stats?.customers ?? 0}\n'
                        'Leads: ${authenticate.stats?.leads ?? 0}\n'
                        'Suppliers: ${authenticate.stats?.suppliers ?? 0}',
                  );
                case 1:
                  return _DashboardCard(
                    title: 'Users',
                    iconName: 'people',
                    route: '/users',
                    stats:
                        'Employees: ${authenticate.company?.employees.length ?? 0}',
                  );
                default:
                  return _DashboardCard(
                    title: 'Companies & Users',
                    iconName: 'groups',
                    route: '/companiesUsers',
                    stats: 'Leads: ${authenticate.stats?.leads ?? 0}',
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;
  final String stats;

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
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
