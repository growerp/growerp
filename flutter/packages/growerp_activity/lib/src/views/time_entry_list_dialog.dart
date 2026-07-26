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

import '../../growerp_activity.dart';

class TimeEntryListDialog extends StatefulWidget {
  final String activityId;
  final List<TimeEntry> timeEntries;
  const TimeEntryListDialog(this.activityId, this.timeEntries, {super.key});
  @override
  TimeEntryListState createState() => TimeEntryListState();
}

class TimeEntryListState extends State<TimeEntryListDialog> {
  late ActivityBloc activityBloc;
  late ActivityLocalizations _localizations;
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
    _localizations = ActivityLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);

    return Dialog(
      key: const Key('TimeEntryListDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        child: _showList(isPhone(context)),
        title: _localizations.timeEntry_listTitle,
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
                      _localizations.timeEntry_updateSuccess,
                      Colors.green,
                    );
                    Navigator.of(context).pop();
                    break;
                  case ActivityBlocStatus.failure:
                    HelperFunctions.showMessage(
                      context,
                      _localizations.activity_error(state.message ?? 'unknown'),
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
                            _localizations.timeEntry_notFound,
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
              tooltip: _localizations.activity_addNew,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
