/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:responsive_framework/responsive_framework.dart';
import '../tasks.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({Key? key, required this.task, required this.index})
      : super(key: key);

  final Task task;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(task.taskName != null ? task.taskName![0] : '')),
            title: Row(
              children: <Widget>[
                Expanded(
                    child: Text("${task.taskName}", key: Key('name$index'))),
                Expanded(
                    child: Text("${task.status}", key: Key('status$index'))),
                Text(task.unInvoicedHours!.toString(),
                    key: Key('unInvoicedHours$index')),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(
                      child: Text("${task.description}",
                          key: Key('description$index'),
                          textAlign: TextAlign.center)),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(
                      child: Text("${task.rate}",
                          key: Key('rate$index'), textAlign: TextAlign.center)),
              ],
            ),
            onTap: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                        value: context.read<TaskBloc>(),
                        child: TaskDialog(task));
                  });
            },
            trailing: IconButton(
                key: Key('delete$index'),
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  context
                      .read<TaskBloc>()
                      .add(TaskUpdate(task.copyWith(status: 'Closed')));
                })));
  }
}
