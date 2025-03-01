// ignore_for_file: depend_on_referenced_packages

/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class WorkflowEditorMainMenu extends StatefulWidget {
  final Task workflow;
  final Dashboard dashboard;
  final Offset position;
  const WorkflowEditorMainMenu(this.workflow, this.dashboard, this.position,
      {super.key});
  @override
  WorkflowEditorMainMenuState createState() => WorkflowEditorMainMenuState();
}

class WorkflowEditorMainMenuState extends State<WorkflowEditorMainMenu> {
  late TaskWorkflowTemplateBloc _workflowTemplateBloc;
  late List<FlowElement> elementsSave;

  @override
  void initState() {
    super.initState();
    _workflowTemplateBloc = context.read<TaskWorkflowTemplateBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        key: const Key('TaskDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            title: 'Workflow Shapes',
            height: 200,
            width: 300,
            child: _showForm()));
  }

  Widget _showForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Wrap(
        spacing: 10,
        children: [
          InkWell(
            onTap: () {
              widget.dashboard.addElement(FlowElement(
                  position: widget.position - const Offset(40, 40),
                  size: const Size(80, 80),
                  text: '${widget.dashboard.elements.length}',
                  kind: ElementKind.diamond,
                  handlers: [
                    Handler.bottomCenter,
                    Handler.topCenter,
                    Handler.leftCenter,
                    Handler.rightCenter,
                  ]));
              Navigator.of(context).pop();
            },
            child: Image.asset('packages/growerp_core/images/diamond.png'),
          ),
          InkWell(
            onTap: () {
              widget.dashboard.addElement(FlowElement(
                  position: widget.position - const Offset(50, 25),
                  size: const Size(100, 50),
                  text: '${widget.dashboard.elements.length}',
                  kind: ElementKind.rectangle,
                  handlers: [
                    Handler.bottomCenter,
                    Handler.topCenter,
                    Handler.leftCenter,
                    Handler.rightCenter,
                  ]));
              Navigator.of(context).pop();
            },
            child: Image.asset('packages/growerp_core/images/rect.png'),
          ),
          InkWell(
            onTap: () {
              widget.dashboard.addElement(FlowElement(
                  position: widget.position - const Offset(50, 25),
                  size: const Size(100, 50),
                  text: '${widget.dashboard.elements.length}',
                  kind: ElementKind.oval,
                  handlers: [
                    Handler.bottomCenter,
                    Handler.topCenter,
                    Handler.leftCenter,
                    Handler.rightCenter,
                  ]));
              Navigator.of(context).pop();
            },
            child: Image.asset('packages/growerp_core/images/oval.png'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(children: [
        const SizedBox(width: 10),
        OutlinedButton(
          child: const Text('Re-load'),
          onPressed: () async {
            widget.dashboard.removeAllElements();
            List<FlowElement> elements =
                Dashboard.fromJson(widget.workflow.jsonImage).elements;
            for (FlowElement element in elements) {
              widget.dashboard.addElement(element);
            }
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 20),
        Expanded(
          child: OutlinedButton(
              child: const Text('Save'),
              onPressed: () {
                _workflowTemplateBloc.add(TaskUpdate(widget.workflow));
                Navigator.pop(context);
              }),
        ),
      ])
    ]);
  }
}
