/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_insurance/growerp_insurance.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for the insurance example app, used by the
/// app and by the integration tests.
const insuranceMenuConfig = MenuConfiguration(
  menuConfigurationId: 'INSURANCE_EXAMPLE',
  appId: 'insurance_example',
  name: 'Insurance Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'INSURANCE_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'InsuranceDashboard',
    ),
    MenuItem(
      itemKey: 'INSURANCE_POLICIES',
      title: 'Policies',
      route: '/policies',
      iconName: 'shield',
      sequenceNum: 20,
      widgetName: 'PolicyList',
    ),
    MenuItem(
      itemKey: 'INSURANCE_RENEWALS',
      title: 'Renewals',
      route: '/renewals',
      iconName: 'autorenew',
      sequenceNum: 30,
      widgetName: 'PolicyRenewalList',
    ),
    MenuItem(
      itemKey: 'INSURANCE_CLAIMS',
      title: 'Claims',
      route: '/claims',
      iconName: 'report',
      sequenceNum: 40,
      widgetName: 'ClaimList',
    ),
    MenuItem(
      itemKey: 'INSURANCE_COMMISSIONS',
      title: 'Commissions',
      route: '/commissions',
      iconName: 'payments',
      sequenceNum: 50,
      widgetName: 'CommissionList',
    ),
    MenuItem(
      itemKey: 'INSURANCE_MY_POLICIES',
      title: 'My Policies',
      route: '/myPolicies',
      iconName: 'shield',
      sequenceNum: 60,
      widgetName: 'MyPoliciesView',
    ),
  ],
);

GoRouter createInsuranceExampleRouter() {
  return createStaticAppRouter(
    menuConfig: insuranceMenuConfig,
    appTitle: 'GrowERP Insurance Example',
    dashboard: const InsuranceDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/policies' => const PolicyList(),
      '/renewals' => const PolicyRenewalList(),
      '/claims' => const ClaimList(),
      '/commissions' => const CommissionList(),
      '/myPolicies' => const MyPoliciesView(),
      _ => const InsuranceDashboard(),
    },
  );
}

/// BLoC providers for the insurance example app.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getInsuranceBlocProviders(restClient),
  ];
}

/// Localizations delegates for the insurance example app.
List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
  InsuranceLocalizations.delegate,
];

class InsuranceDashboard extends StatelessWidget {
  const InsuranceDashboard({super.key});

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
              menuItemId: 'policies',
              title: 'Policies',
              iconName: 'shield',
              route: '/policies',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'claims',
              title: 'Claims',
              iconName: 'report',
              route: '/claims',
              tileType: 'statistic',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
