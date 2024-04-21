import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:dropdown_search/dropdown_search.dart';

class WorkflowDashboard extends StatefulWidget {
  const WorkflowDashboard({Key? key}) : super(key: key);

  @override
  _WorkflowDashboardState createState() => _WorkflowDashboardState();
}

class _WorkflowDashboardState extends State<WorkflowDashboard> {
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
              chips.add(InputChip(
                label: Text(
                  workflow.taskName,
                  key: Key('addWorkflow'),
                ),
                deleteIcon: const Icon(
                  Icons.cancel,
                  key: Key("deleteChip"),
                ),
                onDeleted: () async {
                  taskBloc.add(TaskDeleteUserWorkflow(workflow.taskId));
                },
                onPressed: () async {
                  Navigator.of(context)
                      .pushNamed('/workflowRunner', arguments: workflow);
                },
              ));
            }
            chips.add(SizedBox(
              width: 250,
              height: 35,
              child: DropdownSearch<Task>(
                key: const Key('taskDropDown'),
                popupProps: PopupProps.menu(
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
                asyncItems: (String filter) {
                  taskBloc.add(
                      TaskFetch(searchString: filter, isForDropDown: true));
                  return Future.value(taskState.tasks);
                },
                validator: (value) => value == null ? 'field required' : null,
              ),
            ));
          }
          return Padding(
              padding: EdgeInsets.only(right: 20),
              child: Wrap(spacing: 10, children: chips));
        case TaskBlocStatus.failure:
          return HelperFunctions.showMessage(
              context, 'Error: ${taskState.message}', Colors.red);
        default:
          return CircularProgressIndicator();
      }
    });
  }
}
