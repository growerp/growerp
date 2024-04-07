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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../growerp_task.dart';

class TaskDialog extends StatefulWidget {
  final Task task;
  const TaskDialog(this.task, {super.key});
  @override
  TaskDialogState createState() => TaskDialogState();
}

class TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _routingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _workflowSearchBoxController =
      TextEditingController();
  TaskStatus? _status;
  late TaskBloc _taskBloc;
  Task? _selectedWorkflow = Task();

  @override
  void initState() {
    super.initState();
    if (widget.task.taskType == TaskType.todo) {
      _status = widget.task.statusId ?? TaskStatus.planning;
    }
    _nameController.text = widget.task.taskName;
    _descriptionController.text = widget.task.description;
    _routingController.text = widget.task.routing ?? '';
    _taskBloc = context.read<TaskBloc>();
  }

  @override
  Widget build(BuildContext context) {
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
                    case TaskBlocStatus.success:
                      HelperFunctions.showMessage(
                          context,
                          '${widget.task.taskId.isEmpty ? "Add" : "Update"} successfull',
                          Colors.green);
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      break;
                    case TaskBlocStatus.failure:
                      HelperFunctions.showMessage(
                          context, 'Error: ${state.message}', Colors.red);
                      break;
                    default:
                      const Text("????");
                  }
                },
                child: popUp(
                  context: context,
                  title: '${widget.task.taskType} Information',
                  height: 400,
                  width: 400,
                  child: _showForm(isPhone(context)),
                ))));
  }

  Widget _showForm(isPhone) {
    return Center(
        child: Form(
            key: _formKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                  child: Text(
                      "Task${widget.task.taskId.isEmpty ? "New" : widget.task.taskId}",
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),
              if (widget.task.taskType != TaskType.workflow)
                TextFormField(
                  key: const Key('name'),
                  decoration: InputDecoration(
                      labelText: '${widget.task.taskType} Name'),
                  controller: _nameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a ${widget.task.taskType} name?';
                    }
                    return null;
                  },
                ),
              if (widget.task.taskType != TaskType.workflow)
                TextFormField(
                  key: const Key('description'),
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  controller: _descriptionController,
                ),
              if (widget.task.taskType != TaskType.workflowTemplate &&
                  widget.task.taskType != TaskType.workflowTaskTemplate &&
                  widget.task.taskType != TaskType.workflow)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: DropdownButtonFormField<TaskStatus>(
                        key: const Key('statusDropDown'),
                        decoration: const InputDecoration(labelText: 'Status'),
                        hint: const Text('Status'),
                        value: _status,
                        validator: (value) =>
                            value == null ? 'field required' : null,
                        items: TaskStatus.values
                            .map((taskStatus) => DropdownMenuItem<TaskStatus>(
                                  value: taskStatus,
                                  child: Text(taskStatus.name),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _status = newValue!;
                          });
                        },
                        isExpanded: true)),
              if (widget.task.taskType != TaskType.workflowTemplate &&
                  widget.task.taskType != TaskType.workflow)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                        key: const Key('routing'),
                        decoration: InputDecoration(
                            labelText: '${widget.task.taskType} Routing'),
                        controller: _routingController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a ${widget.task.taskType} routing?';
                          }
                          return null;
                        })),
              const SizedBox(height: 20),
              Row(children: [
                if (widget.task.taskId.isNotEmpty &&
                    widget.task.taskType == TaskType.todo)
                  ElevatedButton(
                      key: const Key('TimeEntries'),
                      child: const Text('TimeEntries'),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _taskBloc,
                                  child: TimeEntryListDialog(widget.task.taskId,
                                      widget.task.timeEntries));
                            });
                      }),
                if (widget.task.taskType == TaskType.workflowTemplate &&
                    widget.task.taskId.isNotEmpty &&
                    widget.task.taskType != TaskType.workflow)
                  Expanded(
                      child: ElevatedButton(
                          key: const Key('editWorkflow'),
                          child: const Text('Edit Workflow'),
                          onPressed: () => Navigator.of(context).pushNamed(
                              '/editWorkflow',
                              arguments: widget.task))),
                if (widget.task.taskType == TaskType.workflow)
                  Expanded(
                      child: ElevatedButton(
                          key: const Key('startWorkflow'),
                          child: const Text('Start Workflow'),
                          onPressed: () => Navigator.of(context).pushNamed(
                              '/workflowRunner',
                              arguments: widget.task))),
                const SizedBox(width: 10),
                if (widget.task.taskType != TaskType.workflow)
                  Expanded(
                      child: ElevatedButton(
                          key: const Key('update'),
                          child: Text(
                              widget.task.taskId.isEmpty ? 'Create' : 'Update'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _taskBloc.add(TaskUpdate(
                                widget.task.copyWith(
                                  taskId: widget.task.taskId,
                                  taskName: _nameController.text,
                                  description: _descriptionController.text,
                                  routing: _routingController.text,
                                  statusId: _status,
                                ),
                              ));
                            }
                          })),
                if (widget.task.taskType == TaskType.workflow)
                  BlocBuilder<TaskWorkflowBloc, TaskState>(
                      builder: (context, state) {
                    switch (state.status) {
                      case TaskBlocStatus.failure:
                        return const FatalErrorForm(
                            message: 'server connection problem');
                      case TaskBlocStatus.success:
                        return DropdownSearch<Task>(
                          key: const Key('taskDropDown'),
                          selectedItem: _selectedWorkflow,
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              autofocus: true,
                              decoration:
                                  const InputDecoration(labelText: 'Task id'),
                              controller: _workflowSearchBoxController,
                            ),
                            title: popUp(
                              context: context,
                              title: 'Select Workflow Task Template',
                              height: 50,
                            ),
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Workflow Task Template',
                            ),
                          ),
                          itemAsString: (Task? u) =>
                              " ${u!.taskName}", // invisible char for test
                          onChanged: (Task? newValue) {
                            _selectedWorkflow = newValue ?? Task();
                          },
                          asyncItems: (String filter) {
                            _taskBloc.add(TaskFetch(
                                searchString: filter, isForDropDown: true));
                            return Future.value(state.tasks);
                          },
                          validator: (value) =>
                              value == null ? 'field required' : null,
                        );
                      default:
                        return const Center(child: CircularProgressIndicator());
                    }
                  }),
              ]),
            ])));
  }
}
