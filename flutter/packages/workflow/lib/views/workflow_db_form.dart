/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:dropdown_search/dropdown_search.dart';
import '../menu_options.dart';

class WorkflowDbForm extends StatefulWidget {
  const WorkflowDbForm({super.key});

  @override
  State<WorkflowDbForm> createState() => _WorkflowDbFormState();
}

class _WorkflowDbFormState extends State<WorkflowDbForm> {
  late TaskBloc taskBloc;
  final TextEditingController _taskSearchBoxController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    taskBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc
      // get all workflow templates
      ..add(const TaskFetch(isForDropDown: true, my: false))
      // get a MY workflow templates
      ..add(const TaskGetUserWorkflows(TaskType.workflowTemplate));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, authState) {
      return BlocBuilder<TaskWorkflowTemplateBloc, TaskState>(
          builder: (context, taskState) {
        if (authState.status == AuthStatus.authenticated &&
            taskState.status == TaskBlocStatus.success) {
          List<Widget> chips = [];
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
              //    selectedItem: _selectedTemplate,
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
                taskBloc
                    .add(TaskFetch(searchString: filter, isForDropDown: true));
                return Future.value(taskState.tasks);
              },
              validator: (value) => value == null ? 'field required' : null,
            ),
          ));
          Authenticate authenticate = authState.authenticate!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: 10),
              Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Wrap(spacing: 10, children: chips)),
              Expanded(
                child: DashBoardForm(dashboardItems: [
                  makeDashboardItem('dbWorkflows', context, menuOptions[1],
                      ["Currently active workflows", "Workflows start here"]),
                  makeDashboardItem('dbWorkflowTemplates', context,
                      menuOptions[2], ["Workflow definitions"]),
                  //          makeDashboardItem('dbWorkflowTemplateTasks', context, menuOptions[3],
                  //              ["Workflow Task definitions"]),
                  makeDashboardItem('dbToDos', context, menuOptions[3], [
                    authenticate.company!.name!.length > 20
                        ? "${authenticate.company!.name!.substring(0, 20)}..."
                        : "${authenticate.company!.name}",
                    "All open tasks: ${authenticate.stats?.allTasks ?? 0}",
                    "Not Invoiced hours: ${authenticate.stats?.notInvoicedHours ?? 0}",
                  ]),
                ]),
              ),
            ],
          );
        }

        return const LoadingIndicator();
      });
    });
  }
}
