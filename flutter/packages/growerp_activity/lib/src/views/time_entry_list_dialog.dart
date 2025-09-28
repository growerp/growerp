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

import '../../growerp_activity.dart';
import '../l10n/activity_localizations.dart';

class TimeEntryListDialog extends StatefulWidget {
  final String activityId;
  final List<TimeEntry> timeEntries;
  const TimeEntryListDialog(this.activityId, this.timeEntries, {super.key});
  @override
  TimeEntryListState createState() => TimeEntryListState();
}

class TimeEntryListState extends State<TimeEntryListDialog> {
  late ActivityBloc activityBloc;
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    activityBloc = context.read<ActivityBloc>();
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    right = right ?? (isAPhone(context) ? 20 : 50);

    return Dialog(
      key: const Key('TimeEntryListDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        child: _showList(isPhone(context)),
        title: ActivityLocalizations.of(context)!.timeEntry_listTitle,
        height: 400,
        width: 400,
      ),
    );
  }

  Widget _showList(bool isPhone) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {},
          child: Center(
            child: BlocListener<ActivityBloc, ActivityState>(
              listener: (context, state) async {
                switch (state.status) {
                  case ActivityBlocStatus.success:
                    HelperFunctions.showMessage(
                      context,
                      ActivityLocalizations.of(context)!.timeEntry_updateSuccess,
                      Colors.green,
                    );
                    Navigator.of(context).pop();
                    break;
                  case ActivityBlocStatus.failure:
                    HelperFunctions.showMessage(
                      context,
                      ActivityLocalizations.of(context)!
                          .activity_error(state.message ?? 'unknown'),
                      Colors.red,
                    );
                    break;
                  default:
                    const Text("????");
                }
              },
              child: BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state_) {
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.timeEntries.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (widget.timeEntries.isEmpty) {
                        return Center(
                          heightFactor: 20,
                          child: Text(
                            ActivityLocalizations.of(context)!.timeEntry_notFound,
                            key: const Key('empty'),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      if (index == 0) {
                        return TimeEntryListHeader(
                          activityBloc: context.read<ActivityBloc>(),
                        );
                      }
                      index--;
                      return TimeEntryListItem(
                        index: index,
                        activityId: '',
                        timeEntry: widget.timeEntries[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
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
            child: FloatingActionButton(
              key: const Key("addNew"),
              heroTag: "timeEntryAdd",
              onPressed: () async {
                await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                      value: activityBloc,
                      child: TimeEntryDialog(
                        TimeEntry(activityId: widget.activityId),
                      ),
                    );
                  },
                );
              },
              tooltip: ActivityLocalizations.of(context)!.activity_addNew,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
