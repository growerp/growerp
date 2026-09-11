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

class OnboardingTaskList extends StatefulWidget {
  const OnboardingTaskList({super.key});

  @override
  OnboardingTaskListState createState() => OnboardingTaskListState();
}

class OnboardingTaskListState extends State<OnboardingTaskList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late OnboardingTaskBloc _onboardingTaskBloc;
  List<OnboardingTask> onboardingTasks = const <OnboardingTask>[];
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _onboardingTaskBloc = context.read<OnboardingTaskBloc>()
      ..add(const OnboardingTasksFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<OnboardingTaskBloc, OnboardingTaskState>(
      listener: (context, state) {
        if (state.status == OnboardingTaskStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == OnboardingTaskStatus.success) _isLoading = false;
      },
      builder: (context, state) {
        onboardingTasks = state.onboardingTasks;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) => _onboardingTaskBloc.add(
                OnboardingTaskSearchChanged(searchString: value),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getOnboardingTaskListColumns(context),
                    rows: onboardingTasks
                        .map(
                          (onboardingTask) => getOnboardingTaskListRow(
                            context: context,
                            onboardingTask: onboardingTask,
                            index: onboardingTasks.indexOf(onboardingTask),
                            bloc: _onboardingTaskBloc,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && onboardingTasks.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(onboardingTasks[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: 'hrOnboardingTaskAdd',
                      key: const Key('addNew'),
                      onPressed: () => _showDialog(OnboardingTask()),
                      tooltip: localizations.newOnboardingTask,
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

  void _showDialog(OnboardingTask onboardingTask) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _onboardingTaskBloc,
        child: OnboardingTaskDialog(onboardingTask),
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) _onboardingTaskBloc.add(OnboardingTasksFetch(limit: limit));
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
