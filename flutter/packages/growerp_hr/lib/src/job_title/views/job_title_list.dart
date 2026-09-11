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

class JobTitleList extends StatefulWidget {
  const JobTitleList({super.key});

  @override
  JobTitleListState createState() => JobTitleListState();
}

class JobTitleListState extends State<JobTitleList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late JobTitleBloc _jobTitleBloc;
  List<JobTitle> jobTitles = const <JobTitle>[];
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _jobTitleBloc = context.read<JobTitleBloc>()
      ..add(const JobTitlesFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<JobTitleBloc, JobTitleState>(
      listener: (context, state) {
        if (state.status == JobTitleStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == JobTitleStatus.success) _isLoading = false;
      },
      builder: (context, state) {
        jobTitles = state.jobTitles;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) =>
                  _jobTitleBloc.add(JobTitleSearchChanged(searchString: value)),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getJobTitleListColumns(context),
                    rows: jobTitles
                        .map(
                          (jobTitle) => getJobTitleListRow(
                            context: context,
                            jobTitle: jobTitle,
                            index: jobTitles.indexOf(jobTitle),
                            bloc: _jobTitleBloc,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && jobTitles.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(jobTitles[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: 'hrJobTitleAdd',
                      key: const Key('addNew'),
                      onPressed: () => _showDialog(JobTitle()),
                      tooltip: localizations.newJobTitle,
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

  void _showDialog(JobTitle jobTitle) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _jobTitleBloc,
        child: JobTitleDialog(jobTitle),
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) _jobTitleBloc.add(JobTitlesFetch(limit: limit));
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
