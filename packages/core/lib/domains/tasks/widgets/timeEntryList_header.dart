import 'package:core/domains/tasks/bloc/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class TimeEntryListHeader extends StatelessWidget {
  const TimeEntryListHeader({Key? key, required this.taskBloc})
      : super(key: key);
  final TaskBloc taskBloc;

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
      title: Column(children: [
        Row(children: <Widget>[
          Expanded(child: Text("Date")),
          Container(child: Text("Hours")),
          if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
            Expanded(child: Text("From/To Party", textAlign: TextAlign.center)),
          if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
            Expanded(child: Text("Comments", textAlign: TextAlign.center)),
        ]),
        Divider(color: Colors.black),
      ]),
    ));
  }
}
