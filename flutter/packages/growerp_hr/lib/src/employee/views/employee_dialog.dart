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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_hr.dart';

/// Add or maintain an employee: the personal data is only entered when the
/// employee (and its login) is created, after that the HR fields, the
/// onboarding checklist and the yearly leave allowances can be maintained.
class EmployeeDialog extends StatefulWidget {
  final Employee employee;
  const EmployeeDialog(this.employee, {super.key});
  @override
  EmployeeDialogState createState() => EmployeeDialogState();
}

class EmployeeDialogState extends State<EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _annualController = TextEditingController();
  final _sickController = TextEditingController();
  String? _jobTitleId;
  String? _departmentPartyId;
  String? _managerPartyId;
  DateTime? _hireDate;
  EmployeeStatus _status = EmployeeStatus.onboarding;
  late Employee employee;
  late bool isNew;
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    employee = widget.employee;
    isNew = employee.partyId.isEmpty;
    _firstNameController.text = employee.firstName;
    _lastNameController.text = employee.lastName;
    _emailController.text = employee.email ?? '';
    _jobTitleId = employee.jobTitleId;
    _departmentPartyId = employee.departmentPartyId;
    _managerPartyId = employee.managerPartyId;
    _hireDate = employee.hireDate?.toLocal();
    _status = employee.status ?? EmployeeStatus.onboarding;
    if (!isNew) {
      context.read<LeaveRequestBloc>().add(
        LeaveBalancesFetch(partyId: employee.partyId, year: _year),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('EmployeeDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: MultiBlocListener(
        listeners: [
          BlocListener<LeaveRequestBloc, LeaveRequestState>(
            listenWhen: (previous, current) =>
                current.status == LeaveRequestStatus.balancesSuccess,
            // never write a controller during build: fill them from the
            // listener when the balances arrive
            listener: (context, state) => _fillAllowances(state.balances),
          ),
          BlocListener<EmployeeBloc, EmployeeState>(
            listener: (context, state) {
              switch (state.status) {
                case EmployeeStatusBloc.success:
                  HelperFunctions.showMessage(
                    context,
                    isNew
                        ? localizations.addSuccess
                        : localizations.updateSuccess,
                    Colors.green,
                  );
                  Navigator.of(context).pop();
                case EmployeeStatusBloc.checklistSuccess:
                  // the checklist is changed while the dialog stays open
                  setState(() {
                    employee = state.employees.firstWhere(
                      (e) => e.partyId == employee.partyId,
                      orElse: () => employee,
                    );
                  });
                case EmployeeStatusBloc.failure:
                  HelperFunctions.showMessage(
                    context,
                    state.message,
                    Colors.red,
                  );
                default:
              }
            },
          ),
        ],
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newEmployee
              : '${localizations.employee}: ${employee.name}',
          height: 700,
          width: isPhone ? 400 : 500,
          child: _showForm(localizations),
        ),
      ),
    );
  }

  Widget _showForm(HrLocalizations localizations) {
    final jobTitles = context.select<JobTitleBloc, List<JobTitle>>(
      (bloc) => bloc.state.jobTitles,
    );
    final departments = context.select<DepartmentBloc, List<Department>>(
      (bloc) => bloc.state.departments,
    );
    final employees = context.select<EmployeeBloc, List<Employee>>(
      (bloc) => bloc.state.employees,
    );
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('listView'),
        children: <Widget>[
          if (isNew) ...[
            TextFormField(
              key: const Key('firstName'),
              decoration: InputDecoration(labelText: localizations.firstName),
              controller: _firstNameController,
              validator: (value) => value == null || value.isEmpty
                  ? '${localizations.firstName}?'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('lastName'),
              decoration: InputDecoration(labelText: localizations.lastName),
              controller: _lastNameController,
              validator: (value) => value == null || value.isEmpty
                  ? '${localizations.lastName}?'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('email'),
              decoration: InputDecoration(labelText: localizations.email),
              controller: _emailController,
              validator: (value) => value == null || !value.contains('@')
                  ? '${localizations.email}?'
                  : null,
            ),
          ] else
            Text(
              '${employee.name} (${employee.email ?? ''})',
              key: const Key('employeeName'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('jobTitle'),
            decoration: InputDecoration(labelText: localizations.jobTitle),
            initialValue: jobTitles.any((j) => j.jobTitleId == _jobTitleId)
                ? _jobTitleId
                : null,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(localizations.none),
              ),
              ...jobTitles.map(
                (jobTitle) => DropdownMenuItem<String>(
                  value: jobTitle.jobTitleId,
                  child: Text(jobTitle.title),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _jobTitleId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('department'),
            decoration: InputDecoration(labelText: localizations.department),
            initialValue:
                departments.any((d) => d.partyId == _departmentPartyId)
                ? _departmentPartyId
                : null,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(localizations.none),
              ),
              ...departments.map(
                (department) => DropdownMenuItem<String>(
                  value: department.partyId,
                  child: Text(department.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _departmentPartyId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('manager'),
            decoration: InputDecoration(labelText: localizations.manager),
            initialValue: employees.any((e) => e.partyId == _managerPartyId)
                ? _managerPartyId
                : null,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(localizations.none),
              ),
              ...employees
                  .where((e) => e.partyId != employee.partyId)
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.partyId,
                      child: Text(e.name),
                    ),
                  ),
            ],
            onChanged: (value) => setState(() => _managerPartyId = value),
          ),
          const SizedBox(height: 10),
          FormBuilderDateTimePicker(
            name: 'hireDate',
            key: const Key('hireDate'),
            initialValue: _hireDate,
            inputType: InputType.date,
            format: DateFormat('yyyy-MM-dd'),
            decoration: InputDecoration(
              labelText: localizations.hireDate,
              hintText: 'yyyy-MM-dd',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onChanged: (value) => _hireDate = value,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<EmployeeStatus>(
            key: const Key('status'),
            decoration: InputDecoration(labelText: localizations.status),
            initialValue: _status,
            items: EmployeeStatus.values
                .where((s) => s != EmployeeStatus.unknown)
                .map(
                  (s) => DropdownMenuItem<EmployeeStatus>(
                    value: s,
                    child: Text(s.name),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _status = value ?? EmployeeStatus.onboarding),
          ),
          if (!isNew) ...[
            const SizedBox(height: 20),
            Text(
              localizations.onboardingChecklist,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...employee.onboardingTasks.map(
              (task) => CheckboxListTile(
                key: Key(
                  'onboardingTask${employee.onboardingTasks.indexOf(task)}',
                ),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(task.description),
                value: task.completed,
                onChanged: (value) => context.read<EmployeeBloc>().add(
                  EmployeeOnboardingTaskUpdate(
                    partyId: employee.partyId,
                    onboardingTaskId: task.onboardingTaskId,
                    completed: value ?? false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${localizations.leaveBalances} $_year',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _allowanceFields(localizations),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('update'),
            child: Text(isNew ? localizations.add : localizations.update),
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              if (!isNew) _saveAllowances();
              context.read<EmployeeBloc>().add(
                EmployeeUpdate(
                  employee.copyWith(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    email: _emailController.text,
                    jobTitleId: _jobTitleId,
                    departmentPartyId: _departmentPartyId,
                    managerPartyId: _managerPartyId,
                    hireDate: hrDateOnly(_hireDate),
                    status: _status,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// yearly allowance per leave type, unpaid leave has no allowance
  Widget _allowanceFields(HrLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('allowanceAnnual'),
            decoration: InputDecoration(
              labelText: '${LeaveType.annual.name} ${localizations.allowance}',
            ),
            controller: _annualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            key: const Key('allowanceSick'),
            decoration: InputDecoration(
              labelText: '${LeaveType.sick.name} ${localizations.allowance}',
            ),
            controller: _sickController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  void _fillAllowances(List<LeaveBalance> balances) {
    Decimal? allowanceOf(LeaveType type) => balances
        .where((b) => b.partyId == employee.partyId && b.leaveType == type)
        .map((b) => b.allowance)
        .firstOrNull;
    if (_annualController.text.isEmpty) {
      _annualController.text = allowanceOf(LeaveType.annual)?.toString() ?? '';
    }
    if (_sickController.text.isEmpty) {
      _sickController.text = allowanceOf(LeaveType.sick)?.toString() ?? '';
    }
  }

  void _saveAllowances() {
    final bloc = context.read<LeaveRequestBloc>();
    for (final entry in {
      LeaveType.annual: _annualController.text,
      LeaveType.sick: _sickController.text,
    }.entries) {
      final days = Decimal.tryParse(entry.value);
      if (days != null) {
        bloc.add(
          LeaveAllowanceUpdate(
            partyId: employee.partyId,
            leaveType: entry.key,
            year: _year,
            days: days,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _annualController.dispose();
    _sickController.dispose();
    super.dispose();
  }
}
