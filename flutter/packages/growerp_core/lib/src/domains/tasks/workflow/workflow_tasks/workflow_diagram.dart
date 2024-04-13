import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';

class WorkflowDiagram extends StatelessWidget {
  final String taskName;
  final String jsonImage;
  const WorkflowDiagram(this.taskName, this.jsonImage, {super.key});

  @override
  Widget build(BuildContext context) {
    Dashboard dashboard = Dashboard.fromJson(jsonImage);
    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
            onPressed: dashboard.recenter,
            child: const Icon(Icons.center_focus_strong)),
        body: Center(
          child: popUp(
            context: context,
            title: taskName,
            padding: 0,
            height: MediaQuery.of(context).size.height - 50,
            width: MediaQuery.of(context).size.width - 50,
            child: FlowChart(
              dashboard: dashboard,
            ),
          ),
        ));
  }
}
