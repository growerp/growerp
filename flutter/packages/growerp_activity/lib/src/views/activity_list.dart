/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../growerp_activity.dart';

class ActivityList extends StatefulWidget {
  final ActivityType activityType;
  final CompanyUser? companyUser;

  const ActivityList(this.activityType, {this.companyUser, super.key});

  @override
  ActivityListState createState() => ActivityListState();
}

class ActivityListState extends State<ActivityList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late ActivityBloc _activityBloc;
  late List<Activity> activities = [];
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _activityBloc = context.read<ActivityBloc>();
    _activityBloc.add(ActivityFetch(
        refresh: true,
        activityType: widget.activityType,
        companyUser: widget.companyUser));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    right = right ?? (isAPhone(context) ? 20 : 50);

    Widget tableView() {
      if (activities.isEmpty) {
        return Center(
            child: Text("No ${widget.activityType}'s found, add one with '+'",
                style: const TextStyle(fontSize: 20.0)));
      }
      // get table data formatted for tableView
      var (
        List<List<TableViewCell>> tableViewCells,
        List<double> fieldWidths,
        double? rowHeight
      ) = get2dTableData<Activity>(getTableData,
          bloc: _activityBloc,
          classificationId: '',
          context: context,
          items: activities);
      return TableView.builder(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        verticalDetails:
            ScrollableDetails.vertical(controller: _scrollController),
        horizontalDetails:
            ScrollableDetails.horizontal(controller: _horizontalController),
        cellBuilder: (context, vicinity) =>
            tableViewCells[vicinity.row][vicinity.column],
        columnBuilder: (index) => index >= tableViewCells[0].length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(fieldWidths[index]),
              ),
        pinnedColumnCount: 1,
        rowBuilder: (index) => index >= tableViewCells.length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(rowHeight!),
                recognizerFactories: <Type, GestureRecognizerFactory>{
                    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                            TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return index > activities.length
                                  ? const BottomLoader()
                                  : Dismissible(
                                      key: const Key('activityItem'),
                                      direction: DismissDirection.startToEnd,
                                      child: BlocProvider.value(
                                          value: _activityBloc,
                                          child: ActivityDialog(
                                              activities[index - 1], null)));
                            }))
                  }),
        pinnedRowCount: 1,
      );
    }

    return BlocConsumer<ActivityBloc, ActivityState>(
        listener: (context, state) {
      if (state.status == ActivityBlocStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
      if (state.status == ActivityBlocStatus.success) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
    }, builder: (context, state) {
      if (state.status == ActivityBlocStatus.failure) {
        return Center(
            child: Text(
                "failed to fetch ${widget.activityType}'s  ${state.message}"));
      }
      if (state.status == ActivityBlocStatus.success) {
        activities = state.activities;
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
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  FloatingActionButton(
                      key: const Key("search"),
                      heroTag: "btn1",
                      onPressed: () async {
                        // find findoc id to show
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              // search separate from finDocBloc
                              return BlocProvider.value(
                                  value:
                                      context.read<DataFetchBloc<Locations>>(),
                                  child:
                                      SearchActivityList(widget.activityType));
                            }).then((value) async => value != null &&
                                context.mounted
                            ?
                            // show detail page
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _activityBloc,
                                      child: ActivityDialog(value, null));
                                })
                            : const SizedBox.shrink());
                      },
                      child: const Icon(Icons.search)),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                      heroTag: 'activityNew',
                      key: const Key("addNew"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _activityBloc,
                                  child: ActivityDialog(
                                      Activity(
                                          activityType: widget.activityType),
                                      widget.companyUser));
                            });
                      },
                      tooltip: CoreLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add))
                ]),
              ),
            ),
          ],
        );
      }
      return const LoadingIndicator();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _activityBloc.add(ActivityFetch(activityType: widget.activityType));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
