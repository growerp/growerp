import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'flowchart_menus.dart';
import 'workflow_context_menu.dart';
import 'workflow_main_menu.dart';

class WorkflowDialog extends StatelessWidget {
  final Task workflow;
  const WorkflowDialog(this.workflow, {super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskWorkflowTemplateBloc>(
          create: (BuildContext context) =>
              TaskBloc(context.read<RestClient>(), TaskType.workflowTemplate),
        ),
        BlocProvider<TaskWorkflowTaskTemplateBloc>(
          create: (BuildContext context) => TaskBloc(
              context.read<RestClient>(), TaskType.workflowTaskTemplate),
        ),
      ],
      child: WorkFlowEditor(workflow),
    );
  }
}

class WorkFlowEditor extends StatefulWidget {
  final Task workflow;
  const WorkFlowEditor(this.workflow, {super.key});

  @override
  State<WorkFlowEditor> createState() => _WorkFlowEditorState();
}

class _WorkFlowEditorState extends State<WorkFlowEditor> {
  late Dashboard dashboard;
  late TaskBloc workflowBloc;
  late TaskBloc taskBloc;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    workflowBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc;
    taskBloc = context.read<TaskWorkflowTaskTemplateBloc>() as TaskBloc;
    if (widget.workflow.jsonImage.isEmpty) {
      dashboard = Dashboard();
    } else {
      dashboard = Dashboard.fromJson(widget.workflow.jsonImage);
    }
    tasks = widget.workflow.workflowTasks;
  }

  @override
  Widget build(BuildContext context) {
    List<Task> syncTasks(List<FlowElement> elements, List<Task> tasks) {
      List<Task> newTasks = [];
      for (FlowElement element in elements) {
        var index = tasks.indexWhere((el) => el.flowElementId == element.id);
        newTasks.add(Task(
            flowElementId: element.id,
            routing: index != -1 ? tasks[index].routing : ''));
      }
      return newTasks;
    }

    return PopScope(
        onPopInvoked: (value) {
          debugPrint("====$tasks $value");
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Workflow Editor'),
          ),
          backgroundColor: Colors.black12,
          body: Container(
            constraints: const BoxConstraints.expand(),
            child: FlowChart(
              dashboard: dashboard,
              onDashboardTapped: ((context, position) async {
                debugPrint('Dashboard tapped $position');
                // copy flowdata into workflow tasks
                tasks = syncTasks(dashboard.elements, tasks);
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: taskBloc,
                        child: WorkFlowMainMenu(
                            widget.workflow.copyWith(workflowTasks: tasks),
                            dashboard,
                            position)));
                tasks = syncTasks(dashboard.elements, tasks);
              }),
              onDashboardSecondaryTapped: (context, position) async {
                debugPrint('Dashboard right clicked $position');
              },
              onDashboardLongtTapped: ((context, position) {
                debugPrint('Dashboard long tapped $position');
              }),
              onDashboardSecondaryLongTapped: ((context, position) {
                debugPrint(
                    'Dashboard long tapped with mouse right click $position');
              }),
              onElementLongPressed: (context, position, element) {
                debugPrint('Element with "${element.text}" text '
                    'long pressed');
              },
              onElementSecondaryLongTapped: (context, position, element) {
                debugPrint('Element with "${element.text}" text '
                    'long tapped with mouse right click');
              },
              onElementPressed: (context, position, element) async {
                debugPrint('Element with "${element.text}" text pressed');
                Task task = Task();
                int index = 0;
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      index = tasks
                          .indexWhere((el) => el.flowElementId == element.id);
                      return BlocProvider.value(
                          value: taskBloc,
                          child: WorkFlowContextMenu(
                            (newTask) {
                              task = newTask;
                            },
                            widget.workflow,
                            dashboard,
                            element,
                            tasks[index],
                          ));
                    });
                if (task.flowElementId != null) {
                  element.setText(task.taskName);
                  tasks[index] = task;
                }
              },
              onElementSecondaryTapped: (context, position, element) {
                debugPrint('Element with "${element.text}" text pressed');
              },
              onHandlerPressed: (context, position, handler, element) {
                debugPrint('handler pressed: position $position '
                    'handler $handler" of element $element');
                FlowchartMenus.displayHandlerMenu(
                    context, position, handler, element, dashboard);
              },
              onHandlerLongPressed: (context, position, handler, element) {
                debugPrint('handler long pressed: position $position '
                    'handler $handler" of element $element');
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
              onPressed: dashboard.recenter,
              child: const Icon(Icons.center_focus_strong)),
        ));
  }
}
