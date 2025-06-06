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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../growerp_task.dart';

class TaskList extends StatefulWidget {
  final TaskType taskType;
  const TaskList(this.taskType, {super.key});

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  final _scrollController = ScrollController();
  late TaskBloc _taskBloc;
  bool hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    switch (widget.taskType) {
      case TaskType.todo:
        _taskBloc = context.read<TaskBloc>();
      default:
    }
    _taskBloc.add(const TaskFetch(refresh: true, taskType: TaskType.todo));
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      Widget showForm(state) {
        return RefreshIndicator(
            onRefresh: (() async =>
                _taskBloc.add(const TaskFetch(refresh: true))),
            child: ListView.builder(
              key: const Key('listView'),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: hasReachedMax && state.tasks.isNotEmpty
                  ? state.tasks.length + 1
                  : state.tasks.length + 2,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(children: [
                    TaskListHeader(widget.taskType),
                    const Divider(),
                  ]);
                }
                if (index == 1 && state.tasks.isEmpty) {
                  return const Center(
                      heightFactor: 20,
                      child: Text("no records found!",
                          key: Key('empty'), textAlign: TextAlign.center));
                }
                index -= 1;
                return index >= state.tasks.length
                    ? const BottomLoader()
                    : Dismissible(
                        key: const Key('taskItem'),
                        direction: DismissDirection.startToEnd,
                        child: BlocProvider.value(
                          value: _taskBloc,
                          child: TaskListItem(
                            task: state.tasks[index],
                            index: index,
                          ),
                        ));
              },
            ));
      }

      blocListener(context, state) {
        if (state.status == TaskBlocStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == TaskBlocStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }

      blocBuilder(context, state) {
        if (state.status == TaskBlocStatus.failure) {
          return FatalErrorForm(
              message: "Could not load ${widget.taskType.toString()}s!");
        }
        if (state.status == TaskBlocStatus.success) {
          hasReachedMax = state.hasReachedMax;
          return showForm(state);
        }
        return const LoadingIndicator();
      }

      switch (widget.taskType) {
        case TaskType.todo:
          return BlocConsumer<TaskBloc, TaskState>(
              listener: blocListener, builder: blocBuilder);
        default:
          return BlocConsumer<TaskBloc, TaskState>(
              listener: blocListener, builder: blocBuilder);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _taskBloc.add(const TaskFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
