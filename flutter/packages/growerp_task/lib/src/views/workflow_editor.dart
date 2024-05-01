import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../growerp_task.dart';

class WorkflowEditorDialog extends StatelessWidget {
  final Task workflow;
  const WorkflowEditorDialog(this.workflow, {super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskWorkflowTemplateBloc>(
          create: (BuildContext context) => TaskBloc(
              context.read<RestClient>(), TaskType.workflowTemplate, {}),
        ),
        BlocProvider<TaskWorkflowTaskTemplateBloc>(
          create: (BuildContext context) => TaskBloc(
              context.read<RestClient>(), TaskType.workflowTaskTemplate, {}),
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
  late TaskWorkflowTemplateBloc workflowTemplateBloc;
  late TaskWorkflowTaskTemplateBloc taskTemplateBloc;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    workflowTemplateBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc;
    taskTemplateBloc = context.read<TaskWorkflowTaskTemplateBloc>() as TaskBloc;
    if (widget.workflow.jsonImage.isEmpty) {
      dashboard = Dashboard();
    } else {
      dashboard = Dashboard.fromJson(widget.workflow.jsonImage);
    }
    tasks = List.of(widget.workflow.workflowTasks);
  }

  @override
  Widget build(BuildContext context) {
    List<Task> syncTasks(List<FlowElement> elements, List<Task> tasks) {
      List<Task> newTasks = [];
      for (FlowElement element in elements) {
        var index = tasks.indexWhere((el) => el.flowElementId == element.id);
        if (index == -1) {
          newTasks.add(Task(flowElementId: element.id));
        } else {
          newTasks.add(tasks[index].copyWith(flowElementId: element.id));
        }
      }
      return newTasks;
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
            onPressed: dashboard.recenter,
            child: const Icon(Icons.center_focus_strong)),
        body: Center(
            child: popUp(
          context: context,
          title: widget.workflow.taskName,
          padding: 0,
          height: MediaQuery.of(context).size.height - 50,
          width: MediaQuery.of(context).size.width - 50,
          child: Container(
            constraints: const BoxConstraints.expand(),
            child: FlowChart(
              dashboard: dashboard,
              onDashboardTapped: ((context, position) async {
                debugPrint('Dashboard tapped $position');
                tasks = syncTasks(dashboard.elements, tasks);
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: workflowTemplateBloc,
                        child: WorkflowEditorMainMenu(
                            widget.workflow.copyWith(
                                workflowTasks: tasks,
                                jsonImage: dashboard.toJson()),
                            dashboard,
                            position)));
                tasks = syncTasks(dashboard.elements, tasks);
              }),
              onDashboardSecondaryTapped: (context, position) async {
                debugPrint('Dashboard right clicked $position');
                // copy flowdata into workflow tasks
                tasks = syncTasks(dashboard.elements, tasks);
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: workflowTemplateBloc,
                        child: WorkflowEditorMainMenu(
                            widget.workflow.copyWith(
                                workflowTasks: tasks,
                                jsonImage: dashboard.toJson()),
                            dashboard,
                            position)));
                tasks = syncTasks(dashboard.elements, tasks);
              },
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
                      if (index == -1) {
                        return const Center(
                            child: Text('Could not find element!'));
                      }
                      return BlocProvider.value(
                          value: taskTemplateBloc,
                          child: WorkflowEditorContextMenu(
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
        )));
  }
}
