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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../../growerp_activity.dart';
import 'activity_list_styled_data.dart';

class ActivityList extends StatefulWidget {
  final ActivityType activityType;
  final CompanyUser? companyUser;

  const ActivityList(this.activityType, {this.companyUser, super.key});

  @override
  ActivityListState createState() => ActivityListState();
}

class ActivityListState extends State<ActivityList> {
  final _scrollController = ScrollController();
  late ActivityBloc _activityBloc;
  late ActivityLocalizations _localizations;
  late List<Activity> activities = [];
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _activityBloc = context.read<ActivityBloc>();
    _activityBloc.add(
      ActivityFetch(
        refresh: true,
        activityType: widget.activityType,
        companyUser: widget.companyUser,
      ),
    );
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = ActivityLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      final rows = activities.map((activity) {
        final index = activities.indexOf(activity);
        return getActivityListRow(
          context: context,
          activity: activity,
          index: index,
          bloc: _activityBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getActivityListColumns(context, widget.activityType),
        rows: rows,
        isLoading: _isLoading && activities.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('activityItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _activityBloc,
                  child: ActivityDialog(activities[index], null),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state.status == ActivityBlocStatus.failure) {
          HelperFunctions.showMessage(
            context,
            _localizations.activity_error(state.message ?? 'unknown'),
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == ActivityBlocStatus.loading;
        if (state.status == ActivityBlocStatus.failure) {
          return Center(
            child: Text(
              _localizations.activity_fetchError(
                widget.activityType.toString(),
                state.message ?? '',
              ),
            ),
          );
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        key: const Key("search"),
                        heroTag: "btn1",
                        onPressed: () async {
                          await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                value: context
                                    .read<DataFetchBloc<Activities>>(),
                                child: SearchActivityList(widget.activityType),
                              );
                            },
                          ).then(
                            (value) async => value != null && context.mounted
                                ? await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                        value: _activityBloc,
                                        child: ActivityDialog(value, null),
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
                                  Activity(activityType: widget.activityType),
                                  widget.companyUser,
                                ),
                              );
                            },
                          );
                        },
                        tooltip: _localizations.activity_addNew,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
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
