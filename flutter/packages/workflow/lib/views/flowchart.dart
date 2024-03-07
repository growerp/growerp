import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';

import 'flowchart_menus.dart';

class Flowchart extends StatefulWidget {
  const Flowchart({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Flowchart> createState() => _FlowchartState();
}

class _FlowchartState extends State<Flowchart> {
  Dashboard dashboard = Dashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.black12,
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: FlowChart(
          dashboard: dashboard,
          onDashboardTapped: ((context, position) {
            debugPrint('Dashboard tapped $position');
            FlowchartMenus.displayDashboardMenu(context, position, dashboard);
          }),
          onDashboardSecondaryTapped: (context, position) {
            debugPrint('Dashboard right clicked $position');
            FlowchartMenus.displayDashboardMenu(context, position, dashboard);
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
                context, position, element, dashboard);
          },
          onElementSecondaryTapped: (context, position, element) {
            debugPrint('Element with "${element.text}" text pressed');
            FlowchartMenus.displayElementMenu(
                context, position, element, dashboard);
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
    );
  }
}
