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

import 'package:growerp_core/growerp_core.dart';

import '../growerp_hr.dart';

/// Widget mappings for the HR package
Map<String, GrowerpWidgetBuilder> getHrWidgets() {
  return {
    'MyHrView': (args) => const MyHrView(),
    'EmployeeList': (args) => const EmployeeList(),
    'LeaveRequestList': (args) => const LeaveRequestList(),
    'DepartmentList': (args) => const DepartmentList(),
    'JobTitleList': (args) => const JobTitleList(),
    'OnboardingTaskList': (args) => const OnboardingTaskList(),
  };
}

/// Widget metadata with icons and keywords for the HR package
List<WidgetMetadata> getHrWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'MyHrView',
      description:
          'Employee self service: own job title, department, manager, hire '
          'date, onboarding checklist, leave balances and own leave requests',
      iconName: 'person',
      keywords: ['my hr', 'self service', 'my leave', 'my profile'],
      builder: (args) => const MyHrView(),
    ),
    WidgetMetadata(
      widgetName: 'EmployeeList',
      description:
          'Employees with job title, department, manager, hire date, '
          'employment status and onboarding checklist',
      iconName: 'people',
      keywords: ['employee', 'staff', 'personnel', 'onboarding', 'hr'],
      builder: (args) => const EmployeeList(),
    ),
    WidgetMetadata(
      widgetName: 'LeaveRequestList',
      description: 'Leave requests of the employees, approve or reject them',
      iconName: 'luggage',
      keywords: ['leave', 'holiday', 'vacation', 'absence', 'time off'],
      builder: (args) => const LeaveRequestList(),
    ),
    WidgetMetadata(
      widgetName: 'DepartmentList',
      description: 'Departments of the company and their manager',
      iconName: 'apartment',
      keywords: ['department', 'organization', 'unit'],
      builder: (args) => const DepartmentList(),
    ),
    WidgetMetadata(
      widgetName: 'JobTitleList',
      description: 'Job titles which can be assigned to employees',
      iconName: 'work',
      keywords: ['job title', 'position', 'function'],
      builder: (args) => const JobTitleList(),
    ),
    WidgetMetadata(
      widgetName: 'OnboardingTaskList',
      description: 'The company onboarding checklist used for new employees',
      iconName: 'checklist',
      keywords: ['onboarding', 'checklist', 'new hire'],
      builder: (args) => const OnboardingTaskList(),
    ),
  ];
}
