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

class TaskListForm extends StatelessWidget {
  final TaskType taskType;
  const TaskListForm(this.taskType, {super.key});

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    switch (taskType) {
      case TaskType.todo:
        return BlocProvider<TaskToDoBloc>(
          create: (context) => TaskBloc(restClient, taskType),
          child: TaskList(taskType),
        );
      case TaskType.workflow:
        return BlocProvider<TaskWorkflowBloc>(
          create: (context) => TaskBloc(restClient, taskType),
          child: TaskList(taskType),
        );
      case TaskType.workflowTemplate:
        return BlocProvider<TaskWorkflowTemplateBloc>(
          create: (context) => TaskBloc(restClient, taskType),
          child: TaskList(taskType),
        );
      case TaskType.workflowTaskTemplate:
        return BlocProvider<TaskWorkflowTaskTemplateBloc>(
          create: (context) => TaskBloc(restClient, taskType),
          child: TaskList(taskType),
        );
      default:
        return BlocProvider<TaskBloc>(
          create: (context) => TaskBloc(restClient, taskType),
          child: TaskList(taskType),
        );
    }
  }
}

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
        _taskBloc = context.read<TaskToDoBloc>() as TaskBloc;
        break;
      case TaskType.workflow:
        _taskBloc = context.read<TaskWorkflowBloc>() as TaskBloc;
        break;
      case TaskType.workflowTemplate:
        _taskBloc = context.read<TaskWorkflowTemplateBloc>() as TaskBloc;
        break;
      case TaskType.workflowTaskTemplate:
        _taskBloc = context.read<TaskWorkflowTaskTemplateBloc>() as TaskBloc;
        break;
      default:
    }
    _taskBloc.add(const TaskFetch());
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
                        key: const Key('userItem'),
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
          return Scaffold(
              floatingActionButton: FloatingActionButton(
                  key: const Key("addNew"),
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                              value: _taskBloc,
                              child:
                                  TaskDialog(Task(taskType: widget.taskType)));
                        });
                  },
                  tooltip: widget.taskType == TaskType.workflow
                      ? 'Start new workflow'
                      : 'Add New Task',
                  child: Icon(widget.taskType == TaskType.workflow
                      ? Icons.start
                      : Icons.add)),
              body: showForm(state));
        }
        return const LoadingIndicator();
      }

      switch (widget.taskType) {
        case TaskType.todo:
          return BlocConsumer<TaskToDoBloc, TaskState>(
              listener: blocListener, builder: blocBuilder);
        case TaskType.workflow:
          return BlocConsumer<TaskWorkflowBloc, TaskState>(
              listener: blocListener, builder: blocBuilder);
        case TaskType.workflowTemplate:
          return BlocConsumer<TaskWorkflowTemplateBloc, TaskState>(
              listener: blocListener, builder: blocBuilder);
        case TaskType.workflowTaskTemplate:
          return BlocConsumer<TaskWorkflowTaskTemplateBloc, TaskState>(
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
