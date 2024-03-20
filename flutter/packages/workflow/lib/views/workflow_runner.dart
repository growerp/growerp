import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class WorkflowRunner extends StatelessWidget {
  const WorkflowRunner({super.key, required this.workflow});
  final Task workflow;

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    return BlocProvider<TaskBloc>(
        create: (context) => TaskBloc(restClient, workflow.taskType)
          ..add(TaskWorkflowNext(workflow)),
        child: BlocConsumer<TaskBloc, TaskState>(listener: (context, state) {
          switch (state.status) {
            case TaskBlocStatus.success:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
              Navigator.of(context).pop();
              break;
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
            case TaskBlocStatus.workflowAction:
              return BlocProvider.value(
                  value: context.read<TaskBloc>(),
                  child: DisplayMenuOption(
                    menuList: state.menuOptions,
                    menuIndex: 0,
                    workflow: workflow,
                  ));
            case TaskBlocStatus.loading:
            case TaskBlocStatus.initial:
              return const LoadingIndicator();
            default:
              return const FatalErrorForm(
                  message: "Internet or server problem?");
          }
        }));
  }
}
