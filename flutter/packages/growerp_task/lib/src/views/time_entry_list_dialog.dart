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

import '../../growerp_task.dart';

class TimeEntryListDialog extends StatefulWidget {
  final String taskId;
  final List<TimeEntry> timeEntries;
  const TimeEntryListDialog(this.taskId, this.timeEntries, {super.key});
  @override
  TimeEntryListState createState() => TimeEntryListState();
}

class TimeEntryListState extends State<TimeEntryListDialog> {
  late TaskBloc taskBloc;

  @override
  void initState() {
    super.initState();
    taskBloc = context.read<TaskBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        key: const Key('TimeEntryListDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            child: _showList(isPhone(context)),
            title: 'Time Entry Information',
            height: 400,
            width: 400));
  }

  Widget _showList(isPhone) {
    double top = 0;
    double left = 250;
    return Stack(
      children: [
        GestureDetector(
            onTap: () {},
            child: Center(
                child: BlocListener<TaskBloc, TaskState>(
                    listener: (context, state) async {
              switch (state.status) {
                case TaskBlocStatus.success:
                  HelperFunctions.showMessage(
                      context, 'Update successfull', Colors.green);
                  Navigator.of(context).pop();
                  break;
                case TaskBlocStatus.failure:
                  HelperFunctions.showMessage(
                      context, 'Error: ${state.message}', Colors.red);
                  break;
                default:
                  const Text("????");
              }
            }, child: BlocBuilder<TaskBloc, TaskState>(
                        builder: (context, state_) {
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: widget.timeEntries.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (widget.timeEntries.isEmpty) {
                    return const Center(
                        heightFactor: 20,
                        child: Text('No time entries found',
                            key: Key('empty'), textAlign: TextAlign.center));
                  }
                  if (index == 0) {
                    return TimeEntryListHeader(
                      taskBloc: context.read<TaskBloc>(),
                    );
                  }
                  index--;
                  return TimeEntryListItem(
                      index: index,
                      taskId: '',
                      timeEntry: widget.timeEntries[index]);
                },
              );
            })))),
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                left += details.delta.dx;
                top += details.delta.dy;
              });
            },
            child: FloatingActionButton(
                key: const Key("addNew"),
                onPressed: () async {
                  await showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return BlocProvider.value(
                            value: taskBloc,
                            child: TimeEntryDialog(
                                TimeEntry(taskId: widget.taskId)));
                      });
                },
                tooltip: 'Add New',
                child: const Icon(Icons.add)),
          ),
        ),
      ],
    );
  }
}
