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

import '../workflow/workflow_menu_options.dart';
import '../workflow/workflow_tasks/workflow_tasks.dart';

part 'task_event.dart';
part 'task_state.dart';

const _taskLimit = 20;

mixin TaskToDoBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowTemplateBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowTaskTemplateBloc on Bloc<TaskEvent, TaskState> {}

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
        TaskWorkflowTaskTemplateBloc {
  TaskBloc(this.restClient, this.taskType, this.screens)
      : super(const TaskState()) {
    on<TaskFetch>(_onTaskFetch,
        transformer: taskDroppable(const Duration(milliseconds: 100)));
    on<TaskUpdate>(_onTaskUpdate);
    on<TaskTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<TaskTimeEntryDelete>(_onTimeEntryDelete);
    on<TaskWorkflowNext>(_onTaskWorkflowNext);
    on<TaskWorkflowPrevious>(_onTaskWorkflowPrevious);
    on<TaskWorkflowCancel>(_onTaskWorkflowCancel);
    on<TaskWorkflowSuspend>(_onTaskWorkflowSuspend);
    on<TaskSetReturnString>(_onTaskSetReturnString);
    on<TaskGetUserWorkflows>(_onTaskGetUserWorkflows);
    on<TaskCreateUserWorkflow>(_onTaskCreateUserWorkflow);
    on<TaskDeleteUserWorkflow>(_onTaskDeleteUserWorkflow);
  }

  final RestClient restClient;
  final TaskType taskType;
  final Map<String, Widget>? screens;
  int start = 0;

  /// general fetch of task type entities
  Future<void> _onTaskFetch(
    TaskFetch event,
    Emitter<TaskState> emit,
  ) async {
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
          my: event.my,
          start: start,
          searchString: event.searchString,
          limit: event.limit,
          taskId: event.taskId,
          isForDropDown: event.isForDropDown);
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
        if (index != -1) tasks[index] = compResult;
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
        // copy all tasks from the template and set statusId
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
        // create new workflow with all the tasks
        currentWorkflow = await restClient.createTask(
            task: currentWorkflow.copyWith(
                taskType: TaskType.workflow,
                taskId: "",
                parentTaskId: currentWorkflow.taskId, // use template in parent
                statusId: TaskStatus.progress,
                workflowTasks: newTasks));
      } else {
        // workflow is now created, check return code last task if any
        // find just finished task within workflow by statusId
        int lastTaskIndex = currentWorkflow.workflowTasks
            .indexWhere((task) => task.statusId == TaskStatus.progress);

        // check return string from last task currently just a number
        int? nextTaskIndex = int.tryParse(state.returnString) ?? 0;
        // reset value
        add(const TaskSetReturnString(""));

        // find next tasks, yes can be more than one
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
          // update status of finished last task
          await restClient.updateTask(
              task: currentWorkflow.workflowTasks[lastTaskIndex]
                  .copyWith(statusId: TaskStatus.completed));
          // finish workflow
          Task workflow = await restClient.updateTask(
              task: currentWorkflow.copyWith(statusId: TaskStatus.completed));
          return emit(state.copyWith(
              currentWorkflow: workflow,
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
            } else if (index == nextTaskIndexes[nextTaskIndex]) {
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

      // get task to be executed
      Task nextTask = currentWorkflow.workflowTasks.firstWhere(
        (task) => task.statusId == TaskStatus.progress,
        orElse: () => Task(),
      );
      if (nextTask.taskId.isEmpty) {
        debugPrint("system error: no next Task found!");
      }

      // get screen location first local, the if not found from
      // repository screens

      Widget? child;
      if (nextTask.routing != null) {
        List<String> routings = nextTask.routing!.split(',');

        Map<String, Widget> localScreens = {
          'selectScreen':
              SelectWorkflowTask(currentWorkflow.taskId, routings.sublist(1)),
          'textScreen': TextWorkflowTask(routings.sublist(1)),
        };
        // first parameter is class. next are parameters
        child = localScreens[routings[0]] ?? screens?[routings[0]];
      }

      // setup menuOptions use workflowMenuOptions.dart as basis
      workflowMenuOptions.first = workflowMenuOptions.first.copyWith(
        title: nextTask.taskName,
        child: child ?? Text(nextTask.routing ?? 'no routing'),
        arguments: {
          'menuList': workflowMenuOptions,
          'workflow': currentWorkflow,
        },
      );

      workflowMenuOptions[1] = workflowMenuOptions[1].copyWith(
        child: WorkflowDiagram(
            currentWorkflow.taskName, currentWorkflow.jsonImage),
        arguments: workflowMenuOptions,
      );
      emit(state.copyWith(
        menuOptions: workflowMenuOptions,
        currentWorkflow: currentWorkflow,
        message:
            "Workflow ${state.currentWorkflow == null ? 'Started' : 'Next task'}"
            " ${nextTask.taskName}",
        status: TaskBlocStatus.workflowAction,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
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
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
    }
  }

  void _onTaskSetReturnString(
    TaskSetReturnString event,
    Emitter<TaskState> emit,
  ) {
    return emit(state.copyWith(
      returnString: event.returnString,
    ));
  }

  Future<void> _onTaskGetUserWorkflows(
    TaskGetUserWorkflows event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskBlocStatus.loading));
    try {
      Tasks result = await restClient.getUserWorkflow(taskType: event.taskType);
      return emit(state.copyWith(
          status: TaskBlocStatus.success, myTasks: result.tasks));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onTaskCreateUserWorkflow(
    TaskCreateUserWorkflow event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));
      Tasks result =
          await restClient.createUserWorkflow(workflowId: event.workflowId);
      return emit(state.copyWith(
          status: TaskBlocStatus.success,
          myTasks: result.tasks,
          message: 'workflow added'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onTaskDeleteUserWorkflow(
    TaskDeleteUserWorkflow event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskBlocStatus.loading));
      await restClient.deleteUserWorkflow(workflowId: event.workflowId);
      List<Task> tasks = List.of(state.myTasks);
      int index =
          tasks.indexWhere((element) => element.taskId == event.workflowId);
      if (index != -1) tasks.removeAt(index);
      return emit(state.copyWith(
          status: TaskBlocStatus.success,
          myTasks: tasks,
          message: 'Workflow deleted'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: TaskBlocStatus.failure,
          tasks: [],
          message: await getDioError(e)));
    }
  }
}
