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
import 'package:growerp_models/growerp_models.dart';
import '../../../api_repository.dart';
import '../tasks.dart';

class TaskListForm extends StatelessWidget {
  const TaskListForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => TaskBloc(context.read<APIRepository>()),
      child: const TasksList(),
    );
  }
}

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  TasksListState createState() => TasksListState();
}

class TasksListState extends State<TasksList> {
  final _scrollController = ScrollController();
  late TaskBloc _taskBloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _taskBloc = context.read<TaskBloc>();
    _taskBloc.add(const TaskFetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        switch (state.status) {
          case TaskStatus.failure:
            return Center(
                child: Text('failed to fetch tasks: ${state.message}'));
          case TaskStatus.success:
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                    key: const Key("addNew"),
                    onPressed: () async {
                      await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                                value: _taskBloc, child: TaskDialog(Task()));
                          });
                    },
                    tooltip: 'Add New',
                    child: const Icon(Icons.add)),
                body: RefreshIndicator(
                    onRefresh: (() async => context
                        .read<TaskBloc>()
                        .add(const TaskFetch(refresh: true))),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.hasReachedMax
                          ? state.tasks.length + 1
                          : state.tasks.length + 2,
                      controller: _scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (state.tasks.isEmpty) {
                          return const Center(
                              heightFactor: 20,
                              child: Text('No active tasks found',
                                  key: Key('empty'),
                                  textAlign: TextAlign.center));
                        }
                        if (index == 0) return const TaskListHeader();
                        index--;
                        return index >= state.tasks.length
                            ? const BottomLoader()
                            : TaskListItem(
                                task: state.tasks[index], index: index);
                      },
                    )));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<TaskBloc>().add(const TaskFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
