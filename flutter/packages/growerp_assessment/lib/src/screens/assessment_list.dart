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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/assessment_bloc.dart';
import 'assessment_detail_screen.dart';
import 'assessment_list_table_def.dart';

// Table padding and background decoration
const assessmentPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getAssessmentBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

class AssessmentList extends StatefulWidget {
  const AssessmentList({super.key});

  @override
  AssessmentListState createState() => AssessmentListState();
}

class AssessmentListState extends State<AssessmentList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late AssessmentBloc _assessmentBloc;
  List<Assessment> assessments = const <Assessment>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (assessments.isEmpty) {
            return const Center(
              child: Text(
                'No assessments found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<Assessment>(
            getAssessmentListTableData,
            bloc: _assessmentBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: assessments,
          );

          return TableView.builder(
            diagonalDragBehavior: DiagonalDragBehavior.free,
            verticalDetails: ScrollableDetails.vertical(
              controller: _scrollController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: _horizontalController,
            ),
            cellBuilder: (context, vicinity) =>
                tableViewCells[vicinity.row][vicinity.column],
            columnBuilder: (index) => index >= tableViewCells[0].length
                ? null
                : TableSpan(
                    padding: assessmentPadding,
                    backgroundDecoration: getAssessmentBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: assessmentPadding,
                    backgroundDecoration: getAssessmentBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(rowHeight!),
                    recognizerFactories: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return index > assessments.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key('assessmentDismiss'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _assessmentBloc,
                                          child: AssessmentDetailScreen(
                                            assessment: assessments[index - 1],
                                          ),
                                        ),
                                      );
                              },
                            ),
                      ),
                    },
                  ),
            pinnedRowCount: 1,
          );
        }

        blocListener(context, state) {
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
        }

        blocBuilder(context, state) {
          if (state.status == AssessmentStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load assessments!",
            );
          } else {
            assessments = state.assessments;
            if (assessments.isNotEmpty && _scrollController.hasClients) {
              Future.delayed(const Duration(milliseconds: 100), () {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(currentScroll);
                    }
                  },
                );
              });
            }
            hasReachedMax = state.hasReachedMax;
            return Stack(
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
                      children: [
                        FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "assessmentBtn1",
                          onPressed: () async {
                            // find assessment to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _assessmentBloc,
                                  child: const SearchAssessmentList(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _assessmentBloc,
                                          child: AssessmentDetailScreen(
                                            assessment: value,
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                          child: const Icon(Icons.search),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("addNewAssessment"),
                          heroTag: "assessmentBtn2",
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
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return BlocConsumer<AssessmentBloc, AssessmentState>(
          listener: blocListener,
          builder: blocBuilder,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _assessmentBloc.add(AssessmentFetch(searchString: searchString));
    }
  }
}

class SearchAssessmentList extends StatefulWidget {
  const SearchAssessmentList({super.key});

  @override
  SearchAssessmentListState createState() => SearchAssessmentListState();
}

class SearchAssessmentListState extends State<SearchAssessmentList> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late AssessmentBloc _assessmentBloc;

  @override
  void initState() {
    super.initState();
    _assessmentBloc = context.read<AssessmentBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchAssessmentDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Assessments',
        child: Column(
          children: [
            TextField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search assessments',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => searchBoxController.clear(),
                ),
              ),
              onChanged: (value) {
                _assessmentBloc.add(
                  AssessmentFetch(
                    searchString: value,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<AssessmentBloc, AssessmentState>(
                builder: (context, state) {
                  if (state.status == AssessmentStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.assessments.isEmpty) {
                    return const Center(
                      child: Text('No assessments found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.assessments.length,
                    itemBuilder: (context, index) {
                      final assessment = state.assessments[index];
                      return ListTile(
                        title: Text(assessment.assessmentName),
                        subtitle: Text(
                          assessment.pseudoId ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(assessment),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
