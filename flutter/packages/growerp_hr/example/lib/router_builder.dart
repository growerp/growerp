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
import 'package:growerp_hr/growerp_hr.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for the HR example app, used by the app and
/// by the integration tests.
const hrMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HR_EXAMPLE',
  appId: 'hr_example',
  name: 'HR Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'HR_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'HrDashboard',
    ),
    MenuItem(
      itemKey: 'HR_MY',
      title: 'My HR',
      route: '/hr',
      iconName: 'person',
      sequenceNum: 20,
      widgetName: 'MyHrView',
    ),
    MenuItem(
      itemKey: 'HR_EMPLOYEES',
      title: 'Employees',
      route: '/hr/employees',
      iconName: 'people',
      sequenceNum: 30,
      widgetName: 'EmployeeList',
    ),
    MenuItem(
      itemKey: 'HR_LEAVE',
      title: 'Leave Requests',
      route: '/hr/leave',
      iconName: 'luggage',
      sequenceNum: 40,
      widgetName: 'LeaveRequestList',
    ),
    MenuItem(
      itemKey: 'HR_DEPARTMENTS',
      title: 'Departments',
      route: '/hr/departments',
      iconName: 'apartment',
      sequenceNum: 50,
      widgetName: 'DepartmentList',
    ),
    MenuItem(
      itemKey: 'HR_JOB_TITLES',
      title: 'Job Titles',
      route: '/hr/jobTitles',
      iconName: 'work',
      sequenceNum: 60,
      widgetName: 'JobTitleList',
    ),
    MenuItem(
      itemKey: 'HR_ONBOARDING',
      title: 'Onboarding Tasks',
      route: '/hr/onboarding',
      iconName: 'checklist',
      sequenceNum: 70,
      widgetName: 'OnboardingTaskList',
    ),
  ],
);

GoRouter createHrExampleRouter() {
  return createStaticAppRouter(
    menuConfig: hrMenuConfig,
    appTitle: 'GrowERP HR Example',
    dashboard: const HrDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/hr' => const MyHrView(),
      '/hr/employees' => const EmployeeList(),
      '/hr/leave' => const LeaveRequestList(),
      '/hr/departments' => const DepartmentList(),
      '/hr/jobTitles' => const JobTitleList(),
      '/hr/onboarding' => const OnboardingTaskList(),
      _ => const HrDashboard(),
    },
  );
}

/// BLoC providers for the HR example app.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getHrBlocProviders(restClient),
  ];
}

/// Localizations delegates for the HR example app.
List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
  HrLocalizations.delegate,
];

class HrDashboard extends StatelessWidget {
  const HrDashboard({super.key});

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
              menuItemId: 'myHr',
              title: 'My HR',
              iconName: 'person',
              route: '/hr',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'employees',
              title: 'Employees',
              iconName: 'people',
              route: '/hr/employees',
              tileType: 'statistic',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
