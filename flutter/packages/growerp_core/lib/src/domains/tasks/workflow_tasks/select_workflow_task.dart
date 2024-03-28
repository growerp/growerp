import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class SelectWorkflowTask extends StatelessWidget {
  final List<String> selectText;
  const SelectWorkflowTask(this.selectText, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> selectList = [];
    int index = 0;
    for (var element in selectText) {
      selectList.add(
        InkWell(
            onTap: () {
              context
                  .read<TaskBloc>()
                  .add(TaskSetReturnString(index.toString()));
            },
            child: Text(element)),
      );
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        child: Column(
          children: selectList,
        ),
      ),
    );
  }
}
