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

import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:core/domains/domains.dart';

class TimeEntryListDialog extends StatefulWidget {
  final String taskId;
  final List<TimeEntry> timeEntries;
  TimeEntryListDialog(this.taskId, this.timeEntries);
  @override
  _TimeEntryListState createState() => _TimeEntryListState(timeEntries);
}

class _TimeEntryListState extends State<TimeEntryListDialog> {
  final List<TimeEntry> timeEntries;

  _TimeEntryListState(this.timeEntries);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
            key: Key('TimeEntryListDialog'),
            insetPadding: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                  padding: EdgeInsets.all(20),
                  width: 400,
                  height: 400,
                  child: Center(
                    child: _showList(isPhone),
                  )),
              Positioned(top: 5, right: 5, child: DialogCloseButton())
            ])));
  }

  Widget _showList(isPhone) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            key: Key("addNew"),
            onPressed: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                        value: context.read<TaskBloc>(),
                        child:
                            TimeEntryDialog(TimeEntry(taskId: widget.taskId)));
                  });
            },
            tooltip: 'Add New',
            child: Icon(Icons.add)),
        backgroundColor: Colors.transparent,
        body: GestureDetector(
            onTap: () {},
            child: Center(
                child: Container(
                    child: BlocListener<TaskBloc, TaskState>(
                        listener: (context, state) async {
              switch (state.status) {
                case TaskStatus.success:
                  HelperFunctions.showMessage(
                      context, 'Update successfull', Colors.green);
                  await Future.delayed(Duration(milliseconds: 500));
                  Navigator.of(context).pop();
                  break;
                case TaskStatus.failure:
                  HelperFunctions.showMessage(
                      context, 'Error: ${state.message}', Colors.red);
                  break;
                default:
                  Text("????");
              }
            }, child: BlocBuilder<TaskBloc, TaskState>(
                            builder: (context, state_) {
              return ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: timeEntries.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (timeEntries.isEmpty)
                    return const Center(
                        heightFactor: 20,
                        child: Text('No time entries found',
                            key: Key('empty'), textAlign: TextAlign.center));
                  if (index == 0)
                    return TimeEntryListHeader(
                      taskBloc: context.read<TaskBloc>(),
                    );
                  index--;
                  return TimeEntryListItem(
                      index: index, taskId: '', timeEntry: timeEntries[index]);
                },
              );
            }))))));
  }
}
