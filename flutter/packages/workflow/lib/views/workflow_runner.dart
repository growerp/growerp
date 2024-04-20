import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../workflow_router.dart';

class WorkflowRunner extends StatelessWidget {
  WorkflowRunner({super.key, required this.workflow});
  final Task workflow;
  final _workflowNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    TaskBloc taskBloc = TaskBloc(
        restClient, workflow.taskType, context.read<Map<String, Widget>>())
      ..add(TaskWorkflowNext(workflow.taskId));
    return BlocProvider<TaskBloc>(
        create: (context) => taskBloc..add(TaskWorkflowNext(workflow.taskId)),
        child:
            BlocConsumer<TaskBloc, TaskState>(listener: (context, state) async {
          for (RouteStackItem item in AppNavObserver.navStack) {
            debugPrint("===nav appserver ${item.name} ${item.args}");
          }
          switch (state.status) {
            case TaskBlocStatus.success:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
              Navigator.of(context).pop();
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
            case TaskBlocStatus.workflowAction:
              // start new navigator with own router
              // need to update however the parameters for
              return Navigator(
                  key: _workflowNavigatorKey,
                  initialRoute: '/',
                  onGenerateRoute: workflowGenerateRoute,
                  onGenerateInitialRoutes:
                      (NavigatorState navigator, String initialRouteName) {
                    return [
                      navigator.widget.onGenerateRoute!(
                          RouteSettings(name: '/', arguments: {
                        'menuList': state.menuOptions,
                        'menuIndex': 0,
                        'workflow': state.currentWorkflow,
                      }))!,
                    ];
                  });
            case TaskBlocStatus.loading:
            case TaskBlocStatus.initial:
              return const LoadingIndicator();
            default:
              throw Exception('server connection problem!');
          }
        }));
  }
}
