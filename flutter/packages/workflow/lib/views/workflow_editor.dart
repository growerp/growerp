import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'flow_data.dart';
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
  List<FlowData> flowDatas = [];

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
    for (Task task in widget.workflow.workflowTasks) {
      flowDatas.add(FlowData(
        flowElementId: task.flowElementId!,
        name: task.taskName,
        routing: task.routing ?? '',
        // workflowTaskTemplate: task.workflowTaskTemplate,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (value) {
          debugPrint("====$flowDatas $value");
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
                List<Task> newTasks = [];
                for (FlowData data in flowDatas) {
                  newTasks.add(Task(
                      flowElementId: data.flowElementId,
                      routing: data.routing));
                }
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: taskBloc,
                        child: WorkFlowMainMenu(
                            widget.workflow.copyWith(workflowTasks: newTasks),
                            dashboard,
                            position)));
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
                FlowData flowData = FlowData();
                int index = 0;
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      index = flowDatas
                          .indexWhere((el) => el.flowElementId == element.id);
                      return BlocProvider.value(
                          value: taskBloc,
                          child: WorkFlowContextMenu(
                            (newFlowData) {
                              flowData = newFlowData;
                            },
                            widget.workflow,
                            dashboard,
                            element,
                            flowDatas[index],
                          ));
                    });
                if (flowData.flowElementId.isNotEmpty) {
                  element.setText(flowData.name);
                  flowDatas[index] = flowData;
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
