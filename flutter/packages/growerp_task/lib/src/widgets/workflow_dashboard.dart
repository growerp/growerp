import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:dropdown_search/dropdown_search.dart';

class WorkflowDashboard extends StatefulWidget {
  const WorkflowDashboard({super.key});

  @override
  WorkflowDashboardState createState() => WorkflowDashboardState();
}

class WorkflowDashboardState extends State<WorkflowDashboard> {
  late TaskBloc taskBloc;
  final TextEditingController _taskSearchBoxController =
      TextEditingController();
  late List<Widget> chips;

  @override
  void initState() {
    super.initState();
    taskBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc
      // get all workflow templates
      ..add(const TaskFetch(isForDropDown: true, my: false))
      // get all MY workflow templates
      ..add(const TaskGetUserWorkflows(TaskType.workflowTemplate));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskWorkflowTemplateBloc, TaskState>(
        builder: (context, taskState) {
      chips = [];
      switch (taskState.status) {
        case TaskBlocStatus.success:
          {
            for (Task workflow in taskState.myTasks) {
              chips.add(Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        style: BorderStyle.solid,
                        width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputChip(
                        shape: const LinearBorder(side: BorderSide.none),
                        label: Text(
                          workflow.taskName,
                          key: const Key('addWorkflow'),
                        ),
                        deleteIcon: const Icon(
                          Icons.cancel,
                          key: Key("deleteChip"),
                        ),
                        onDeleted: () async {
                          taskBloc.add(TaskDeleteUserWorkflow(workflow.taskId));
                        },
                        onPressed: () async {
                          Navigator.of(context).pushNamed('/workflowRunner',
                              arguments: workflow);
                        },
                      ),
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        radius: 10,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.show_chart,
                            size: 20,
                          ),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return WorkflowDiagram(
                                      workflow.taskName, workflow.jsonImage);
                                });
                          },
                        ),
                      ),
                      const SizedBox(width: 5)
                    ],
                  )));
            }
            chips.add(SizedBox(
              width: 250,
              height: 35,
              child: DropdownSearch<Task>(
                key: const Key('taskDropDown'),
                popupProps: PopupProps.menu(
                  isFilterOnline: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    controller: _taskSearchBoxController,
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                      labelText: 'Add new Workflow',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
                itemAsString: (Task? u) =>
                    " ${u!.taskName}", // invisible char for test
                onChanged: (Task? newValue) {
                  taskBloc.add(TaskCreateUserWorkflow(newValue!.taskId));
                },
                compareFn: (item, sItem) => item.taskId == sItem.taskId,
                asyncItems: (String filter) {
                  taskBloc.add(
                      TaskFetch(searchString: filter, isForDropDown: true));
                  // remove already selected workflows
                  List<Task> notUsedTasks = [];
                  for (Task task in taskState.tasks) {
                    if (taskState.myTasks
                        .firstWhere((el) => el.taskId == task.taskId,
                            orElse: () => Task())
                        .taskId
                        .isEmpty) {
                      notUsedTasks.add(task);
                    }
                  }
                  return Future.value(notUsedTasks);
                },
                validator: (value) => value == null ? 'field required' : null,
              ),
            ));
          }
          return Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: Wrap(spacing: 10, children: chips));
        case TaskBlocStatus.failure:
          return HelperFunctions.showMessage(
              context, 'Error: ${taskState.message}', Colors.red);
        default:
          return const LoadingIndicator();
      }
    });
  }
}
