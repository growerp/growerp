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
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_hr.dart';

class EmployeeList extends StatefulWidget {
  const EmployeeList({super.key});

  @override
  EmployeeListState createState() => EmployeeListState();
}

class EmployeeListState extends State<EmployeeList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late EmployeeBloc _employeeBloc;
  List<Employee> employees = const <Employee>[];
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _employeeBloc = context.read<EmployeeBloc>()
      ..add(const EmployeesFetch(refresh: true));
    context.read<JobTitleBloc>().add(const JobTitlesFetch(refresh: true));
    context.read<DepartmentBloc>().add(const DepartmentsFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<EmployeeBloc, EmployeeState>(
      listener: (context, state) {
        if (state.status == EmployeeStatusBloc.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == EmployeeStatusBloc.success) _isLoading = false;
      },
      builder: (context, state) {
        employees = state.employees;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) =>
                  _employeeBloc.add(EmployeeSearchChanged(searchString: value)),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getEmployeeListColumns(context),
                    rows: employees
                        .map(
                          (employee) => getEmployeeListRow(
                            context: context,
                            employee: employee,
                            index: employees.indexOf(employee),
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && employees.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(employees[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: 'hrEmployeeAdd',
                      key: const Key('addNew'),
                      onPressed: () => _showDialog(Employee()),
                      tooltip: localizations.newEmployee,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(Employee employee) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _employeeBloc,
        child: EmployeeDialog(employee),
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) _employeeBloc.add(EmployeesFetch(limit: limit));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}
