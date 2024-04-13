import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class SelectWorkflowTask extends StatelessWidget {
  final String workflowId;
  final List<String> selectText;
  const SelectWorkflowTask(this.workflowId, this.selectText, {super.key});

  @override
  Widget build(BuildContext context) {
    List<ButtonSegment> selectList = [];
    int index = 0;
    for (var element in selectText) {
      selectList.add(ButtonSegment(label: Text(element), value: index++));
    }
    return Center(
        child: Container(
      margin: const EdgeInsets.only(top: 100),
      child: SegmentedButton(
          emptySelectionAllowed: true,
          segments: selectList,
          selected: const {},
          onSelectionChanged: (newValue) {
            context
                .read<TaskBloc>()
                .add(TaskSetReturnString(newValue.first.toString()));
            context.read<TaskBloc>().add(TaskWorkflowNext(workflowId));
          }),
    ));
  }
}
