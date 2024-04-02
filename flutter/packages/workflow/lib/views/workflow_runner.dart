import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../menu_options.dart';

class WorkflowRunner extends StatelessWidget {
  const WorkflowRunner({super.key, required this.workflow});
  final Task workflow;

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    TaskBloc taskBloc = TaskBloc(restClient, workflow.taskType)
      ..add(TaskWorkflowNext(workflow.taskId));
    return BlocProvider<TaskBloc>(
        create: (context) => taskBloc..add(TaskWorkflowNext(workflow.taskId)),
        child:
            BlocConsumer<TaskBloc, TaskState>(listener: (context, state) async {
          for (RouteStackItem item in AppNavObserver.navStack) {
            debugPrint("===nav appserver ${item.name} ${item.args}");
          }
          switch (state.status) {
            case TaskBlocStatus.workflowAction:
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                          value: taskBloc,
                          child: DisplayMenuOption(
                              workflow: state.currentWorkflow,
                              menuList: state.menuOptions,
                              menuIndex: 0))));
              taskBloc.add(TaskWorkflowNext(state.currentWorkflow!.taskId));
            case TaskBlocStatus.success:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
              Navigator.of(context).popUntil(ModalRoute.withName('/workflows'));
            case TaskBlocStatus.failure:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.red);
              break;
            default:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
              break;
          }
        }, builder: (context, state) {
          switch (state.status) {
            case TaskBlocStatus.success:
              return DisplayMenuOption(
                menuList: menuOptions,
                menuIndex: 0,
              );
            case TaskBlocStatus.loading:
            case TaskBlocStatus.initial:
              return const LoadingIndicator();
            default:
              return FatalErrorForm(
                  message: state.message ?? 'server connection problem!');
          }
        }));
  }
}
