// ignore_for_file: depend_on_referenced_packages

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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class WorkflowEditorContextMenu extends StatefulWidget {
  final ValueChanged<Task> onTaskChanged;
  final Task workflow;
  final Dashboard dashboard;
  final FlowElement element;
  final Task task;
  const WorkflowEditorContextMenu(this.onTaskChanged, this.workflow,
      this.dashboard, this.element, this.task,
      {super.key});
  @override
  WorkflowEditorContextMenuState createState() =>
      WorkflowEditorContextMenuState();
}

class WorkflowEditorContextMenuState extends State<WorkflowEditorContextMenu> {
  final _taskDialogformKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _routingController = TextEditingController();
  final TextEditingController _taskSearchBoxController =
      TextEditingController();
  late TaskWorkflowTaskTemplateBloc _taskTemplateBloc;
  Task? _selectedTemplate = Task();

  @override
  void initState() {
    super.initState();
    _taskTemplateBloc = context.read<TaskWorkflowTaskTemplateBloc>();
    _taskTemplateBloc.add(const TaskFetch(isForDropDown: true, limit: 3));
    _routingController.text = widget.task.routing ?? '';
    _nameController.text = widget.element.text;
    _selectedTemplate = widget.task.taskTemplate;
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
            child: popUp(
                context: context,
                title: widget.element.text,
                height: 400,
                width: 280,
                child: _showForm())));
  }

  Widget _showForm() {
    return Center(
        child: Form(
            key: _taskDialogformKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        child: const Text('Resize'),
                        onPressed: () async {
                          widget.dashboard
                              .setElementResizable(widget.element, true);
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Delete'),
                        onPressed: () async {
                          widget.dashboard.removeElement(widget.element);
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: const Text('remove outgoing connections'),
                        onPressed: () async {
                          widget.dashboard
                              .removeElementConnections(widget.element);
                          Navigator.of(context).pop();
                        },
                      ),
                    ]),
              ),
              TextFormField(
                key: const Key('name'),
                decoration: const InputDecoration(
                    labelText: 'Workflow Template Task Name'),
                controller: _nameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a task name?';
                  return null;
                },
              ),
              TextFormField(
                key: const Key('routing'),
                decoration: const InputDecoration(
                    labelText: 'Workflow Template task Routing'),
                controller: _routingController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter routing?';
                  return null;
                },
              ),
              BlocBuilder<TaskWorkflowTaskTemplateBloc, TaskState>(
                  builder: (context, state) {
                switch (state.status) {
                  case TaskBlocStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  case TaskBlocStatus.success:
                    return DropdownSearch<Task>(
                      key: const Key('taskDropDown'),
                      selectedItem: _selectedTemplate,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration:
                              const InputDecoration(labelText: 'Task id'),
                          controller: _taskSearchBoxController,
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
                        _selectedTemplate = newValue ?? Task();
                      },
                      asyncItems: (String filter) {
                        _taskTemplateBloc.add(TaskFetch(
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
              const SizedBox(height: 20),
              ElevatedButton(
                  key: const Key('update'),
                  child: Text(
                      widget.workflow.taskId.isEmpty ? 'Create' : 'Update'),
                  onPressed: () {
                    widget.onTaskChanged(widget.task.copyWith(
                        taskName: _nameController.text,
                        taskTemplate: _selectedTemplate,
                        routing: _routingController.text));
                    Navigator.of(context).pop();
                  }),
            ])));
  }
}
