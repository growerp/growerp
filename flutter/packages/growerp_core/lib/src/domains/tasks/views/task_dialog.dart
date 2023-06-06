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
import 'package:responsive_framework/responsive_framework.dart';
import '../../domains.dart';

class TaskDialog extends StatefulWidget {
  final Task task;
  const TaskDialog(this.task, {super.key});
  @override
  TaskDialogState createState() => TaskDialogState();
}

class TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String _status = 'In Planning';

  @override
  void initState() {
    super.initState();
    _status = widget.task.status!;
    _nameController.text = widget.task.taskName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: const Key('TaskDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: BlocListener<TaskBloc, TaskState>(
                listener: (context, state) async {
                  switch (state.status) {
                    case TaskStatus.success:
                      HelperFunctions.showMessage(
                          context,
                          '${widget.task.taskId == null ? "Add" : "Update"} successfull',
                          Colors.green);
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      break;
                    case TaskStatus.failure:
                      HelperFunctions.showMessage(
                          context, 'Error: ${state.message}', Colors.red);
                      break;
                    default:
                      const Text("????");
                  }
                },
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                      padding: const EdgeInsets.all(20),
                      width: 400,
                      height: 400,
                      child: Center(
                        child: _showForm(isPhone),
                      )),
                  const Positioned(
                      top: 10, right: 10, child: DialogCloseButton())
                ]))));
  }

  Widget _showForm(isPhone) {
    return Center(
        child: Form(
            key: _formKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                  child: Text(
                      "Task${widget.task.taskId == null ? "New" : "${widget.task.taskId}"}",
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),
              TextFormField(
                key: const Key('name'),
                decoration: const InputDecoration(labelText: 'Task Name'),
                controller: _nameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a task name?';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: const Key('statusDropDown'),
                decoration: const InputDecoration(labelText: 'Status'),
                hint: const Text('Status'),
                value: _status,
                validator: (value) => value == null ? 'field required' : null,
                items: taskStatusValues
                    .map((label) => DropdownMenuItem<String>(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              Row(children: [
                Visibility(
                    visible: widget.task.taskId != null,
                    child: ElevatedButton(
                        key: const Key('TimeEntries'),
                        child: const Text('TimeEntries'),
                        onPressed: () async {
                          await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                    value: context.read<TaskBloc>(),
                                    child: TimeEntryListDialog(
                                        widget.task.taskId!,
                                        widget.task.timeEntries));
                              });
                        })),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                        key: const Key('update'),
                        child: Text(
                            widget.task.taskId == null ? 'Create' : 'Update'),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            context.read<TaskBloc>().add(TaskUpdate(
                                  Task(
                                    taskId: widget.task.taskId,
                                    taskName: _nameController.text,
                                    status: _status,
                                  ),
                                ));
                          }
                        }))
              ]),
            ])));
  }
}
