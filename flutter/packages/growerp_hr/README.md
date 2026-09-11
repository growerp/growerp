# growerp_hr

HR building block for [GrowERP](https://www.growerp.com): employee onboarding,
leave tracking, job titles, departments and employee self-service.

## Screens

| Widget | Purpose |
|---|---|
| `MyHrView` | self-service: own profile, onboarding checklist, leave balances and own leave requests |
| `EmployeeList` | employees with job title, department, manager, hire date and status (admin) |
| `LeaveRequestList` | leave requests with approve / reject (admin) |
| `DepartmentList` | departments of the company (admin) |
| `JobTitleList` | job titles (admin) |
| `OnboardingTaskList` | the company onboarding checklist template (admin) |

An employee is a regular GrowERP user (`OrgInternal` role, `GROWERP_M_EMPLOYEE`
group) extended with HR fields; a department is a party with the role
`OrgDepartment` linked to the company. Both come from the `growerp` Moqui
component (`HrServices100.xml`).

## Usage

```dart
import 'package:growerp_hr/growerp_hr.dart';

TopApp(
  extraDelegates: [HrLocalizations.delegate],
  extraBlocProviders: getHrBlocProviders(restClient),
  widgetRegistrations: [getHrWidgets()],
);
```
