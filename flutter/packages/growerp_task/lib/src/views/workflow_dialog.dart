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

import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

class WorkflowDialog extends StatefulWidget {
  const WorkflowDialog(this.workflow, {super.key});
  final Task? workflow;

  @override
  WorkflowDialogState createState() => WorkflowDialogState();
}

class WorkflowDialogState extends State<WorkflowDialog> {
  final TextEditingController _taskSearchBoxController =
      TextEditingController();
  late TaskBloc taskBloc;
  Task? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    taskBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc
      // get a MY workflow templates
      ..add(const TaskGetUserWorkflows(TaskType.workflowTemplate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: const Key('WorkflowDialogFull'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: BlocListener<TaskWorkflowTemplateBloc, TaskState>(
                listener: (context, state) async {
                  switch (state.status) {
                    case TaskBlocStatus.success:
                      //           Navigator.of(context).pop();
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
                    title: 'Information workflowtask',
                    height: 200,
                    width: 400,
                    child: Center(
                      child: Column(
                        children: [
                          Center(
                              child: Text(
                                  'Workflow #${widget.workflow == null ? " New" : widget.workflow!.taskId}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  key: const Key('header'))),
                          widget.workflow == null
                              ? BlocBuilder<TaskWorkflowTemplateBloc,
                                  TaskState>(builder: (context, state) {
                                  switch (state.status) {
                                    case TaskBlocStatus.failure:
                                      return const FatalErrorForm(
                                          message: 'server connection problem');
                                    case TaskBlocStatus.success:
                                      return DropdownSearch<Task>(
                                        key: const Key('taskDropDown'),
                                        //    selectedItem: _selectedTemplate,
                                        popupProps: PopupProps.menu(
                                          isFilterOnline: true,
                                          showSearchBox: true,
                                          searchFieldProps: TextFieldProps(
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                                labelText: 'Task id'),
                                            controller:
                                                _taskSearchBoxController,
                                          ),
                                          title: popUp(
                                            context: context,
                                            title:
                                                'Select Workflow Task Template',
                                            height: 50,
                                          ),
                                        ),
                                        dropdownDecoratorProps:
                                            const DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              InputDecoration(
                                            labelText: 'Workflow Task Template',
                                          ),
                                        ),
                                        itemAsString: (Task? u) =>
                                            " ${u!.taskName}", // invisible char for test
                                        onChanged: (Task? newValue) {
                                          _selectedTemplate =
                                              newValue ?? Task();
                                        },
                                        asyncItems: (String filter) {
                                          taskBloc.add(TaskFetch(
                                              searchString: filter,
                                              isForDropDown: true));
                                          return Future.delayed(
                                              const Duration(milliseconds: 150),
                                              () {
                                            return Future.value(
                                                taskBloc.state.tasks);
                                          });
                                        },
                                        compareFn: (item, sItem) =>
                                            item.taskId == sItem.taskId,
                                        validator: (value) => value == null
                                            ? 'field required'
                                            : null,
                                      );
                                    default:
                                      return const Center(
                                          child: LoadingIndicator());
                                  }
                                })
                              : Text(
                                  "Current task ${widget.workflow!.taskName}"),
                          const SizedBox(height: 20),
                          OutlinedButton(
                              key: const Key('startWorkflow'),
                              child: Text(
                                  "${widget.workflow == null ? 'Start' : 'continue'} Workflow?"),
                              onPressed: () => _selectedTemplate != null ||
                                      widget.workflow != null
                                  ? Navigator.of(context).pushNamed(
                                      '/workflowRunner',
                                      arguments:
                                          _selectedTemplate ?? widget.workflow)
                                  : HelperFunctions.showMessage(
                                      context,
                                      'Error: Select workflow name first',
                                      Colors.red)),
                        ],
                      ),
                    )))));
  }
}
