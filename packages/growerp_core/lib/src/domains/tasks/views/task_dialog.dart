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

import '../../common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../domains.dart';

class TaskDialog extends StatefulWidget {
  final Task task;
  TaskDialog(this.task);
  @override
  _TaskState createState() => _TaskState(task);
}

class _TaskState extends State<TaskDialog> {
  final Task task;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();

  String _status = 'In Planning';

  _TaskState(this.task);

  @override
  void initState() {
    super.initState();
    _status = task.status!;
    _nameController.text = task.taskName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: Key('TaskDialog'),
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<TaskBloc, TaskState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case TaskStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${task.taskId == null ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(Duration(milliseconds: 500));
                              Navigator.of(context).pop();
                              break;
                            case TaskStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 400,
                              child: Center(
                                child: _showForm(isPhone),
                              )),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(isPhone) {
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          "Task" +
                              (task.taskId == null ? "New" : "${task.taskId}"),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('name'),
                    decoration: InputDecoration(labelText: 'Task Name'),
                    controller: _nameController,
                    validator: (value) {
                      if (value!.isEmpty) return 'Please enter a task name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: Key('statusDropDown'),
                    decoration: InputDecoration(labelText: 'Status'),
                    hint: Text('Status'),
                    value: _status,
                    validator: (value) =>
                        value == null ? 'field required' : null,
                    items: taskStatusValues
                        .map((label) => DropdownMenuItem<String>(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _status = newValue!;
                      });
                    },
                    isExpanded: true,
                  ),
                  SizedBox(height: 20),
                  Row(children: [
                    Visibility(
                        visible: task.taskId != null,
                        child: ElevatedButton(
                            key: Key('TimeEntries'),
                            child: Text('TimeEntries'),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                        value: context.read<TaskBloc>(),
                                        child: TimeEntryListDialog(
                                            task.taskId!, task.timeEntries));
                                  });
                            })),
                    SizedBox(width: 10),
                    Expanded(
                        child: ElevatedButton(
                            key: Key('update'),
                            child:
                                Text(task.taskId == null ? 'Create' : 'Update'),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                context.read<TaskBloc>().add(TaskUpdate(
                                      Task(
                                        taskId: task.taskId,
                                        taskName: _nameController.text,
                                        status: _status,
                                      ),
                                    ));
                              }
                            }))
                  ]),
                ]))));
  }
}
