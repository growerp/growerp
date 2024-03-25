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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'task_event.dart';
part 'task_state.dart';

const _taskLimit = 20;

mixin TaskToDoBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowTemplateBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowTemplateTaskBloc on Bloc<TaskEvent, TaskState> {}

EventTransformer<E> taskDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Task bloc to service workflow, workflows templates and tasks
/// It also contains the worflow engine.
class TaskBloc extends Bloc<TaskEvent, TaskState>
    with
        TaskToDoBloc,
        TaskWorkflowBloc,
        TaskWorkflowTemplateBloc,
        TaskWorkflowTemplateTaskBloc {
  TaskBloc(this.restClient, this.taskType) : super(const TaskState()) {
    on<TaskFetch>(_onTaskFetch,
        transformer: taskDroppable(const Duration(milliseconds: 100)));
    on<TaskUpdate>(_onTaskUpdate);
    on<TaskTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<TaskTimeEntryDelete>(_onTimeEntryDelete);
    on<TaskWorkflowNext>(_onTaskWorkflowNext);
    on<TaskWorkflowPrevious>(_onTaskWorkflowPrevious);
    on<TaskWorkflowCancel>(_onTaskWorkflowCancel);
    on<TaskWorkflowSuspend>(_onTaskWorkflowSuspend);
  }

  final RestClient restClient;
  final TaskType taskType;
  int start = 0;

  /// general fetch of task type entities
  Future<void> _onTaskFetch(
    TaskFetch event,
    Emitter<TaskState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    if (state.status == TaskBlocStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.tasks.length;
    }
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));
      Tasks compResult = await restClient.getTask(
          taskType: taskType,
          start: start,
          searchString: event.searchString,
          limit: event.limit,
          taskId: event.taskId);
      if (event.taskId.isEmpty) {
        return emit(state.copyWith(
          status: TaskBlocStatus.success,
          tasks: start == 0
              ? compResult.tasks
              : (List.of(state.tasks)..addAll(compResult.tasks)),
          hasReachedMax: compResult.tasks.length < _taskLimit ? true : false,
          searchString: '',
        ));
      } else {
        return emit(
          state.copyWith(
              status: TaskBlocStatus.success,
              currentWorkflow: compResult.tasks.first),
        );
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTaskUpdate(
    TaskUpdate event,
    Emitter<TaskState> emit,
  ) async {
    try {
      List<Task> tasks = List.from(state.tasks);
      emit(state.copyWith(status: TaskBlocStatus.loading));
      if (event.task.taskId.isNotEmpty) {
        // update existing task
        Task compResult = await restClient.updateTask(task: event.task);
        int index =
            tasks.indexWhere((element) => element.taskId == event.task.taskId);
        tasks[index] = compResult;
        return emit(state.copyWith(
            status: TaskBlocStatus.success,
            tasks: tasks,
            message: "${event.task.taskType} updated"));
      } else {
        // add new task
        Task compResult = await restClient.createTask(task: event.task);
        // add task to list
        tasks.insert(0, compResult);
        return emit(state.copyWith(
            status: TaskBlocStatus.success,
            tasks: tasks,
            message: "${event.task.taskType} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTimeEntryUpdate(
    TaskTimeEntryUpdate event,
    Emitter<TaskState> emit,
  ) async {
    try {
      TimeEntry compResult;
      if (event.timeEntry.timeEntryId != null) {
        compResult =
            await restClient.updateTimeEntry(timeEntry: event.timeEntry);
      } else {
        compResult =
            await restClient.createTimeEntry(timeEntry: event.timeEntry);
      }
      List<Task> tasks = List.from(state.tasks);
      int index =
          tasks.indexWhere((element) => element.taskId == compResult.taskId);
      if (event.timeEntry.timeEntryId == null) {
        tasks[index].timeEntries.add(compResult);
      } else {
        int indexTe = tasks[index].timeEntries.indexWhere(
            (element) => element.timeEntryId == compResult.timeEntryId);
        tasks[index].timeEntries[indexTe] = compResult;
      }

      emit(state.copyWith(tasks: tasks));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTimeEntryDelete(
    TaskTimeEntryDelete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      TimeEntry teApiResult =
          await restClient.deleteTimeEntry(timeEntry: event.timeEntry);
      List<Task> tasks = List.from(state.tasks);
      int index =
          tasks.indexWhere((element) => element.taskId == teApiResult.taskId);
      tasks[index].timeEntries.removeWhere(
          (element) => element.timeEntryId == teApiResult.timeEntryId);

      emit(state.copyWith(
        status: TaskBlocStatus.success,
        tasks: tasks,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  /// this contains the workflow engine which serves the next screen
  /// to be displayed, will start a new workflow when not started and
  /// will end the the workflow when the last screen is displayed
  Future<void> _onTaskWorkflowNext(
    TaskWorkflowNext event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));
      List<MenuOption> menuOptions = [
        MenuOption(
          title: "demo workflow",
          route: '/',
          readGroups: [UserGroup.admin, UserGroup.employee],
          child: const Text("Hello world1"),
        ),
        MenuOption(
          title: "demo1 workflow",
          route: '/',
          readGroups: [UserGroup.admin, UserGroup.employee],
          child: const Text("Hello world2"),
        ),
      ];
      // get workflow
      Tasks resultTasks = await restClient.getTask(taskId: event.workflowId);
      Task currentWorkflow = resultTasks.tasks.first;

      // if template: start new active tasks
      if (currentWorkflow.taskType == TaskType.workflowTemplate) {
        // create new active workflow, tasks exracted from json
        // links will be updated in the backend
        List<Task> newTasks = [];

        if (currentWorkflow.workflowTasks.isEmpty) {
          return emit(state.copyWith(
              status: TaskBlocStatus.failure,
              message: "Workflow contains no tasks!"));
        }

        // find first task which has no links
        int firstTaskIndex = currentWorkflow.workflowTasks
            .indexWhere((element) => element.workflowTasks.isEmpty);
        if (firstTaskIndex == -1) {
          return emit(state.copyWith(
              status: TaskBlocStatus.failure,
              message: "starting task not found!"));
        }

        for (int index = 0;
            index < currentWorkflow.workflowTasks.length;
            index++) {
          newTasks.add(currentWorkflow.workflowTasks[index].copyWith(
              taskId: "",
              taskType: TaskType.workflowTask,
              statusId: index == firstTaskIndex
                  ? TaskStatus.progress
                  : TaskStatus.planning));
        }
        // create new workflow
        currentWorkflow = await restClient.createTask(
            task: currentWorkflow.copyWith(
                taskType: TaskType.workflow,
                taskId: "",
                parentTaskId: currentWorkflow.taskId, // use template in parent
                statusId: TaskStatus.progress,
                workflowTasks: newTasks));
      } else {
        // find current task within workflow
        int lastTaskIndex = currentWorkflow.workflowTasks
            .indexWhere((task) => task.statusId == TaskStatus.progress);
        // find next tasks TODO: to be decided with a condition which one to use
        List<int> nextTaskIndexes = [];
        for (int index = 0;
            index < currentWorkflow.workflowTasks.length;
            index++) {
          if (currentWorkflow.workflowTasks[index].workflowTasks
              .where((link) =>
                  link.taskId ==
                  currentWorkflow.workflowTasks[lastTaskIndex].taskId)
              .toList()
              .isNotEmpty) {
            nextTaskIndexes.add(index);
          }
        }

        // check if no new tasks within workflow: complete workflow
        if (nextTaskIndexes.isEmpty) {
          await restClient.updateTask(
              task: currentWorkflow.workflowTasks[lastTaskIndex]
                  .copyWith(statusId: TaskStatus.completed));
          currentWorkflow =
              currentWorkflow.copyWith(statusId: TaskStatus.completed);
          return emit(state.copyWith(
              status: TaskBlocStatus.success,
              message: "Workflow ${currentWorkflow.taskName} completed."));
        } else {
          // update old/new task status
          List<Task> newTasks = [];
          for (int index = 0;
              index < currentWorkflow.workflowTasks.length;
              index++) {
            late TaskStatus newStatusId;
            if (index == lastTaskIndex) {
              newStatusId = TaskStatus.completed;
              await restClient.updateTask(
                  task: currentWorkflow.workflowTasks[index]
                      .copyWith(statusId: newStatusId));
              newTasks.add(currentWorkflow.workflowTasks[index]
                  .copyWith(statusId: newStatusId));
            } else if (index == nextTaskIndexes[0]) {
              newStatusId = TaskStatus.progress;
              await restClient.updateTask(
                  task: currentWorkflow.workflowTasks[index]
                      .copyWith(statusId: newStatusId));
              newTasks.add(currentWorkflow.workflowTasks[index]
                  .copyWith(statusId: newStatusId));
            } else {
              newTasks.add(currentWorkflow.workflowTasks[index]);
            }
          }
          currentWorkflow = currentWorkflow.copyWith(workflowTasks: newTasks);
        }
      }

      // show title of current task
      Task nextTask = currentWorkflow.workflowTasks.firstWhere(
        (task) => task.statusId == TaskStatus.progress,
        orElse: () => Task(),
      );
      if (nextTask.taskId.isEmpty) {
        debugPrint("system error: no started Task found!");
      }
      menuOptions.first = menuOptions.first.copyWith(
        title: nextTask.taskName,
      );

      emit(state.copyWith(
        menuOptions: menuOptions,
        currentWorkflow: currentWorkflow,
        message:
            "Workflow ${state.currentWorkflow == null ? 'Started' : 'Next task'}"
            " ${nextTask.taskName}",
        status: TaskBlocStatus.workflowAction,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTaskWorkflowPrevious(
    TaskWorkflowPrevious event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));

      emit(state.copyWith(
        message: 'previous Workflow',
        status: TaskBlocStatus.workflowAction,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTaskWorkflowSuspend(
    TaskWorkflowSuspend event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));

      emit(state.copyWith(
        message: 'Workflow suspended',
        status: TaskBlocStatus.success,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }

  Future<void> _onTaskWorkflowCancel(
    TaskWorkflowCancel event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));

      emit(state.copyWith(
        message: 'Workflow cancelled',
        status: TaskBlocStatus.success,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure, tasks: [], message: getDioError(e)));
    }
  }
}
