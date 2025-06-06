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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

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

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc(this.restClient) : super(const TaskState()) {
    on<TaskFetch>(_onTaskFetch,
        transformer: taskDroppable(const Duration(milliseconds: 100)));
    on<TaskUpdate>(_onTaskUpdate);
    on<TaskTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<TaskTimeEntryDelete>(_onTimeEntryDelete);
  }

  final RestClient restClient;
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
          taskType: event.taskType,
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
}
