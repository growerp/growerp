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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../domains.dart';
import '../../../services/api_result.dart';
import '../../../services/network_exceptions.dart';
import '../../../api_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

const _taskLimit = 20;

EventTransformer<E> taskDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc(this.repos) : super(const TaskState()) {
    on<TaskFetch>(_onTaskFetch,
        transformer: taskDroppable(const Duration(milliseconds: 100)));
    on<TaskUpdate>(_onTaskUpdate);
    on<TaskTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<TaskTimeEntryDelete>(_onTimeEntryDelete);
  }

  final APIRepository repos;
  Future<void> _onTaskFetch(
    TaskFetch event,
    Emitter<TaskState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    // start from record zero for initial and refresh
    if (state.status == TaskStatus.initial || event.refresh) {
      ApiResult<List<Task>> compResult =
          await repos.getTask(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: TaskStatus.success,
                tasks: data,
                hasReachedMax: data.length < _taskLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: TaskStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<Task>> compResult =
          await repos.getTask(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: TaskStatus.success,
                tasks: data,
                hasReachedMax: data.length < _taskLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: TaskStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search

    ApiResult<List<Task>> compResult =
        await repos.getTask(searchString: event.searchString);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: TaskStatus.success,
              tasks: List.of(state.tasks)..addAll(data),
              hasReachedMax: data.length < _taskLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: TaskStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onTaskUpdate(
    TaskUpdate event,
    Emitter<TaskState> emit,
  ) async {
    List<Task> tasks = List.from(state.tasks);
    if (event.task.taskId != null) {
      ApiResult<Task> compResult = await repos.updateTask(event.task);
      return emit(compResult.when(
          success: (data) {
            int index = tasks
                .indexWhere((element) => element.taskId == event.task.taskId);
            tasks[index] = data;
            return state.copyWith(status: TaskStatus.success, tasks: tasks);
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: TaskStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<Task> compResult = await repos.createTask(event.task);
      return emit(compResult.when(
          success: (data) {
            tasks.insert(0, data);
            return state.copyWith(status: TaskStatus.success, tasks: tasks);
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: TaskStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onTimeEntryUpdate(
    TaskTimeEntryUpdate event,
    Emitter<TaskState> emit,
  ) async {
    ApiResult<TimeEntry> compResult;
    if (event.timeEntry.timeEntryId != null) {
      compResult = await repos.updateTimeEntry(event.timeEntry);
    } else {
      compResult = await repos.createTimeEntry(event.timeEntry);
    }

    emit(compResult.when(
        success: (data) {
          List<Task> tasks = List.from(state.tasks);
          int index =
              tasks.indexWhere((element) => element.taskId == data.taskId);
          if (event.timeEntry.timeEntryId == null) {
            tasks[index].timeEntries.add(data);
          } else {
            int indexTe = tasks[index].timeEntries.indexWhere(
                (element) => element.timeEntryId == data.timeEntryId);
            tasks[index].timeEntries[indexTe] = data;
          }
          return state.copyWith(tasks: tasks);
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: TaskStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onTimeEntryDelete(
    TaskTimeEntryDelete event,
    Emitter<TaskState> emit,
  ) async {
    ApiResult<TimeEntry> teApiResult =
        await repos.deleteTimeEntry(event.timeEntry);

    emit(teApiResult.when(
        success: (data) {
          List<Task> tasks = List.from(state.tasks);
          int index =
              tasks.indexWhere((element) => element.taskId == data.taskId);
          tasks[index].timeEntries.removeWhere(
              (element) => element.timeEntryId == data.timeEntryId);
          return state.copyWith(
            status: TaskStatus.success,
            tasks: tasks,
          );
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: TaskStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}
