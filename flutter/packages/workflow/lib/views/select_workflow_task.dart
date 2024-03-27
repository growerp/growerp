import 'package:flutter/material.dart';

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
              Navigator.of(context).pop(index++);
            },
            child: Text(element)),
      );
    }

    return Column(children: selectList);
  }
}
