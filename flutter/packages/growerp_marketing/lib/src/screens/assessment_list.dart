/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/assessment_bloc.dart';
import 'assessment_detail_screen.dart';
import 'assessment_list_styled_data.dart';

/// List screen for Assessments
class AssessmentList extends StatefulWidget {
  const AssessmentList({super.key});

  @override
  AssessmentListState createState() => AssessmentListState();
}

class AssessmentListState extends State<AssessmentList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late AssessmentBloc _assessmentBloc;
  List<Assessment> assessments = const <Assessment>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  String searchString = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _assessmentBloc = context.read<AssessmentBloc>()
      ..add(const AssessmentFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = assessments.map((assessment) {
        final index = assessments.indexOf(assessment);
        return getAssessmentListRow(
          context: context,
          assessment: assessment,
          index: index,
          bloc: _assessmentBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getAssessmentListColumns(context),
        rows: rows,
        isLoading: _isLoading && assessments.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 80 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('assessmentDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _assessmentBloc,
                  child: AssessmentDetailScreen(
                    assessment: assessments[index],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state.status == AssessmentStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.red,
          );
        }
        if (state.status == AssessmentStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == AssessmentStatus.loading;

        if (state.status == AssessmentStatus.failure && assessments.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load assessments!',
          );
        }

        assessments = state.assessments;
        if (assessments.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }
        hasReachedMax = state.hasReachedMax;

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search assessments...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _assessmentBloc.add(
                  AssessmentFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
                children: [
                  tableView(),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            key: const Key('addNewAssessment'),
                            heroTag: 'assessmentBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _assessmentBloc,
                                    child: const AssessmentDetailScreen(
                                      assessment: Assessment(
                                        assessmentName: '',
                                        status: 'Active',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new assessment',
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
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

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom && !hasReachedMax) {
      _assessmentBloc.add(AssessmentFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
