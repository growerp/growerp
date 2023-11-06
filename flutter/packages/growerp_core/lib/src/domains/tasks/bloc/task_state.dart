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

part of 'task_bloc.dart';

enum TaskStatus { initial, loading, success, failure }

class TaskState extends Equatable {
  const TaskState({
    this.status = TaskStatus.initial,
    this.message,
    this.tasks = const <Task>[],
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final TaskStatus status;
  final String? message;
  final List<Task> tasks;
  final bool hasReachedMax; // all records retrieved
  final String searchString; // check to see if search string first or changed

  TaskState copyWith({
    TaskStatus? status,
    String? message,
    List<Task>? tasks,
    bool? hasReachedMax,
    String? searchString,
    bool? search,
  }) {
    return TaskState(
      status: status ?? this.status,
      message: message,
      tasks: tasks ?? this.tasks,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  String toString() {
    return "$status { hasReachedMax: $hasReachedMax, "
        "tasks: ${tasks.length} message: $message}";
  }

  @override
  List<Object> get props => [status, tasks, hasReachedMax, searchString];
}
