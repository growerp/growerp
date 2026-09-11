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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_hr/growerp_hr.dart';
import 'package:growerp_hr_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP HR test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHrExampleRouter(),
      hrMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppAdmin'),
      title: "HR test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    final random = CommonTest.getRandom();

    // job titles
    final jobTitles = [
      JobTitle(title: 'Developer$random', description: 'writes code'),
      JobTitle(title: 'Accountant$random'),
    ];
    await JobTitleTest.selectJobTitles(tester);
    await JobTitleTest.addJobTitles(tester, jobTitles);
    await JobTitleTest.deleteJobTitle(tester, 'Accountant$random');

    // departments
    final departments = [
      Department(name: 'Engineering$random'),
      Department(name: 'Finance$random'),
    ];
    await DepartmentTest.selectDepartments(tester);
    await DepartmentTest.addDepartments(tester, departments);
    await DepartmentTest.deleteDepartment(tester, 'Finance$random');

    // onboarding checklist template
    final onboardingTasks = [
      OnboardingTask(description: 'Sign contract$random', sequenceNum: 1),
      OnboardingTask(description: 'Hand out laptop$random', sequenceNum: 2),
    ];
    await OnboardingTaskTest.selectOnboardingTasks(tester);
    await OnboardingTaskTest.addOnboardingTasks(tester, onboardingTasks);

    // onboard an employee and activate it
    final employee = Employee(
      firstName: 'Emma',
      lastName: 'Employee$random',
      email: 'emma$random@example.org',
    );
    await EmployeeTest.selectEmployees(tester);
    await EmployeeTest.addEmployees(tester, [employee]);
    await EmployeeTest.checkEmployees(tester, [
      employee.copyWith(status: EmployeeStatus.onboarding),
    ]);
    await EmployeeTest.tickOnboardingTask(tester, employee.lastName, 0);
    await EmployeeTest.updateEmployee(
      tester,
      employee.lastName,
      employee.copyWith(
        jobTitle: 'Developer$random',
        department: 'Engineering$random',
        hireDate: DateTime(DateTime.now().year, 1, 5),
        status: EmployeeStatus.active,
      ),
      annualAllowance: '20',
    );
    await EmployeeTest.checkEmployees(tester, [
      employee.copyWith(
        jobTitle: 'Developer$random',
        department: 'Engineering$random',
        status: EmployeeStatus.active,
      ),
    ]);

    // leave request for that employee, approved by the admin
    await LeaveRequestTest.selectLeaveRequests(tester);
    await LeaveRequestTest.addLeaveRequests(tester, [
      LeaveRequest(
        employeeName: 'Emma',
        leaveType: LeaveType.annual,
        fromDate: DateTime(DateTime.now().year, 3, 2),
        thruDate: DateTime(DateTime.now().year, 3, 6),
        reason: 'holiday',
      ),
    ]);
    await LeaveRequestTest.checkLeaveRequest(
      tester,
      0,
      status: LeaveStatus.pending,
      days: '5',
      employeeName: 'Emma',
    );
    await LeaveRequestTest.setStatus(tester, 0, LeaveStatus.approved);
    await LeaveRequestTest.checkLeaveRequest(
      tester,
      0,
      status: LeaveStatus.approved,
    );

    // self service of the logged in administrator
    await MyHrTest.selectMyHr(tester);
    await MyHrTest.checkProfile(tester, status: EmployeeStatus.onboarding);
    await MyHrTest.checkBalance(tester, LeaveType.annual, '0/0');
    await LeaveRequestTest.addLeaveRequests(tester, [
      LeaveRequest(
        leaveType: LeaveType.unpaid,
        fromDate: DateTime(DateTime.now().year, 4, 6),
        thruDate: DateTime(DateTime.now().year, 4, 8),
        reason: 'own request',
      ),
    ]);
    await LeaveRequestTest.checkLeaveRequest(
      tester,
      0,
      status: LeaveStatus.pending,
      days: '3',
    );
    await LeaveRequestTest.setStatus(tester, 0, LeaveStatus.cancelled);
    await LeaveRequestTest.checkLeaveRequest(
      tester,
      0,
      status: LeaveStatus.cancelled,
    );

    await CommonTest.logout(tester);
  });
}
