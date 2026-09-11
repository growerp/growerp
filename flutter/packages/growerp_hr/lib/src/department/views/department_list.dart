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

class DepartmentList extends StatefulWidget {
  const DepartmentList({super.key});

  @override
  DepartmentListState createState() => DepartmentListState();
}

class DepartmentListState extends State<DepartmentList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late DepartmentBloc _departmentBloc;
  List<Department> departments = const <Department>[];
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _departmentBloc = context.read<DepartmentBloc>()
      ..add(const DepartmentsFetch(refresh: true));
    context.read<EmployeeBloc>().add(const EmployeesFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<DepartmentBloc, DepartmentState>(
      listener: (context, state) {
        if (state.status == DepartmentStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == DepartmentStatus.success) _isLoading = false;
      },
      builder: (context, state) {
        departments = state.departments;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) => _departmentBloc.add(
                DepartmentSearchChanged(searchString: value),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getDepartmentListColumns(context),
                    rows: departments
                        .map(
                          (department) => getDepartmentListRow(
                            context: context,
                            department: department,
                            index: departments.indexOf(department),
                            bloc: _departmentBloc,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && departments.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(departments[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: 'hrDepartmentAdd',
                      key: const Key('addNew'),
                      onPressed: () => _showDialog(Department()),
                      tooltip: localizations.newDepartment,
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

  void _showDialog(Department department) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _departmentBloc,
        child: DepartmentDialog(department),
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) _departmentBloc.add(DepartmentsFetch(limit: limit));
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
