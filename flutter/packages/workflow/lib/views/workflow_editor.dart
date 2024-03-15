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
        BlocProvider<TaskWorkflowBloc>(
          create: (BuildContext context) =>
              TaskBloc(context.read<RestClient>(), TaskType.workflow),
        ),
        BlocProvider<TaskWorkflowTaskBloc>(
          create: (BuildContext context) =>
              TaskBloc(context.read<RestClient>(), TaskType.workflowtask),
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
  late FlowData data;

  @override
  void initState() {
    super.initState();
    workflowBloc = context.read<TaskWorkflowBloc>() as TaskBloc;
    taskBloc = context.read<TaskWorkflowTaskBloc>() as TaskBloc;
    if (widget.workflow.jsonImage.isEmpty) {
      dashboard = Dashboard();
    } else {
      dashboard = Dashboard.fromJson(widget.workflow.jsonImage);
    }
    data = FlowData(
      name: widget.workflow.taskName,
      taskId: widget.workflow.taskId,
      routing: widget.workflow.routing ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (value) {
          print("====$data");
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
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: taskBloc,
                        child: WorkFlowMainMenu(
                            widget.workflow, dashboard, position)));
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

                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => BlocProvider.value(
                        value: taskBloc,
                        child: WorkFlowContextMenu(
                            widget.workflow, dashboard, element, data)));
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
