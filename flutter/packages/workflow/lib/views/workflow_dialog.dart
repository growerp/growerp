import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'flow_data.dart';
import 'flowchart_menus.dart';

class WorkflowDialog extends StatelessWidget {
  final Task workflow;
  const WorkflowDialog(this.workflow, {super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => TaskBloc(context.read<RestClient>())
        ..add(const TaskFetch(
            taskType: TaskType.workflowtask, isForDropDown: true, limit: 3)),
      child: Flowchart(workflow),
    );
  }
}

class Flowchart extends StatefulWidget {
  final Task workflow;
  const Flowchart(this.workflow, {super.key});

  @override
  State<Flowchart> createState() => _FlowchartState();
}

class _FlowchartState extends State<Flowchart> {
  late Dashboard dashboard;
  late TaskBloc taskBloc;
  late FlowData data;

  @override
  void initState() {
    super.initState();
    taskBloc = context.read<TaskBloc>();
    dashboard = Dashboard.fromJson(widget.workflow.jsonImage);
    data = FlowData(
      name: widget.workflow.taskName,
      taskId: widget.workflow.taskId,
      routing: widget.workflow.routing ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Editor'),
      ),
      backgroundColor: Colors.black12,
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: FlowChart(
          dashboard: dashboard,
          onDashboardTapped: ((context, position) {
            debugPrint('Dashboard tapped $position');
            FlowchartMenus.displayDashboardMenu(
                context, position, dashboard, widget.workflow);
          }),
          onDashboardSecondaryTapped: (context, position) {
            debugPrint('Dashboard right clicked $position');
            FlowchartMenus.displayDashboardMenu(
                context, position, dashboard, widget.workflow);
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
          onElementPressed: (context, position, element) {
            debugPrint('Element with "${element.text}" text pressed');

            FlowchartMenus.displayElementMenu(
                context, position, element, FlowData(), dashboard, taskBloc);
          },
          onElementSecondaryTapped: (context, position, element) {
            debugPrint('Element with "${element.text}" text pressed');
            FlowchartMenus.displayElementMenu(
                context, position, element, FlowData(), dashboard, taskBloc);
          },
          onHandlerPressed: (context, position, handler, element) {
            debugPrint('handler pressed: position $position '
                'handler $handler" of element $element');
            FlowchartMenus.displayHandlerMenu(
                context, position, handler, element, data, dashboard);
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
    );
  }
}
