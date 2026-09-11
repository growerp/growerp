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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_hr.dart';

/// Employee self service: own HR data, onboarding checklist, leave balances
/// and own leave requests.
class MyHrView extends StatefulWidget {
  const MyHrView({super.key});

  @override
  MyHrViewState createState() => MyHrViewState();
}

class MyHrViewState extends State<MyHrView> {
  String? _myPartyId;
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _myPartyId = context.read<AuthBloc>().state.authenticate?.user?.partyId;
    context.read<EmployeeBloc>().add(
      EmployeesFetch(refresh: true, partyId: _myPartyId),
    );
    context.read<LeaveRequestBloc>().add(
      LeaveBalancesFetch(partyId: _myPartyId, year: _year),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    return Column(
      key: const Key('MyHrView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<EmployeeBloc, EmployeeState>(
          builder: (context, state) {
            final employee = state.employees
                .where((e) => e.partyId == _myPartyId)
                .firstOrNull;
            if (employee == null) {
              if (state.status == EmployeeStatusBloc.loading ||
                  state.status == EmployeeStatusBloc.initial) {
                return const LoadingIndicator();
              }
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  localizations.noEmployeeRecord,
                  key: const Key('noEmployeeRecord'),
                ),
              );
            }
            return _profile(context, localizations, employee);
          },
        ),
        _balances(context, localizations),
        const Expanded(child: LeaveRequestList(myRequests: true)),
      ],
    );
  }

  Widget _profile(
    BuildContext context,
    HrLocalizations localizations,
    Employee employee,
  ) {
    return Card(
      key: const Key('myProfile'),
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.name,
              key: const Key('myName'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 20,
              runSpacing: 5,
              children: [
                _field(
                  localizations.jobTitle,
                  employee.jobTitle ?? '',
                  'myJobTitle',
                ),
                _field(
                  localizations.department,
                  employee.department ?? '',
                  'myDepartment',
                ),
                _field(
                  localizations.manager,
                  employee.managerName ?? '',
                  'myManager',
                ),
                _field(
                  localizations.hireDate,
                  employee.hireDate?.toLocalizedDateOnly(context) ?? '',
                  'myHireDate',
                ),
                _field(
                  localizations.status,
                  employee.status?.name ?? '',
                  'myStatus',
                ),
              ],
            ),
            if (employee.onboardingTasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                localizations.onboardingChecklist,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...employee.onboardingTasks.map(
                (task) => Row(
                  key: Key(
                    'myOnboardingTask'
                    '${employee.onboardingTasks.indexOf(task)}',
                  ),
                  children: [
                    Icon(
                      task.completed
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Flexible(child: Text(task.description)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, String key) {
    return Text('$label: $value', key: Key(key));
  }

  Widget _balances(BuildContext context, HrLocalizations localizations) {
    return BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
      builder: (context, state) {
        final balances = state.balances
            .where((b) => b.partyId == _myPartyId)
            .toList();
        if (balances.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 20,
            children: [
              Text(
                '${localizations.leaveBalances} $_year:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...balances.map(
                (balance) => Text(
                  '${balance.leaveType?.name ?? ''} '
                  '${balance.used ?? 0}/${balance.allowance ?? 0}',
                  key: Key('balance${balance.leaveType?.name ?? ''}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
