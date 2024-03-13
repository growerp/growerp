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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';

part 'task_event.dart';
part 'task_state.dart';

const _taskLimit = 20;

mixin TaskToDoBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowBloc on Bloc<TaskEvent, TaskState> {}
mixin TaskWorkflowTaskBloc on Bloc<TaskEvent, TaskState> {}

EventTransformer<E> taskDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class TaskBloc extends Bloc<TaskEvent, TaskState>
    with TaskToDoBloc, TaskWorkflowBloc, TaskWorkflowTaskBloc {
  TaskBloc(this.restClient, this.taskType) : super(const TaskState()) {
    on<TaskFetch>(_onTaskFetch,
        transformer: taskDroppable(const Duration(milliseconds: 100)));
    on<TaskUpdate>(_onTaskUpdate);
    on<TaskTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<TaskTimeEntryDelete>(_onTimeEntryDelete);
  }

  final RestClient restClient;
  final TaskType taskType;
  int start = 0;

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
          limit: event.limit);
      return emit(state.copyWith(
        status: TaskBlocStatus.success,
        tasks: start == 0
            ? compResult.tasks
            : (List.of(state.tasks)..addAll(compResult.tasks)),
        hasReachedMax: compResult.tasks.length < _taskLimit ? true : false,
        searchString: '',
      ));
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
      late Task newWorkflow;
      if (event.task.taskId.isNotEmpty) {
        /// extract data from editor data [FlowElement] in growerp [Task]s
        if (event.task.taskType == TaskType.workflow) {
          Dashboard dashboard = Dashboard.fromJson(event.task.jsonImage);
          newWorkflow = Task(
              taskId: event.task.taskId,
              statusId: event.task.statusId,
              taskName: event.task.taskName,
              description: event.task.description);
          List<Task> newWorkflowTasks = [];
          for (FlowElement element in dashboard.elements) {
            if (element == dashboard.elements.first) {
              newWorkflow = newWorkflow.copyWith(
                  flowElementId: element.id, jsonImage: event.task.jsonImage);
            } else {
              newWorkflowTasks.add(Task(
                  taskType: TaskType.workflowtask,
                  flowElementId: element.id,
                  routing: event.task.routing));
            }
          }
          newWorkflow = newWorkflow.copyWith(workflowTasks: newWorkflowTasks);
        } else {
          newWorkflow = event.task;
        }

        Task compResult = await restClient.updateTask(task: newWorkflow);
        int index =
            tasks.indexWhere((element) => element.taskId == event.task.taskId);
        tasks[index] = compResult;
        return emit(state.copyWith(
            status: TaskBlocStatus.success,
            tasks: tasks,
            message: "${event.task.taskType} updated"));
      } else {
        // add
        Task compResult = await restClient.createTask(task: event.task);
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
}
