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

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class Task extends Equatable with _$Task {
  Task._();
  factory Task({
    @Default("") String taskId,
    TaskType? taskType, // todo, workflow, workflowTask
    @Default("") String parentTaskId,
    TaskStatus? statusId,
    @Default("") String taskName,
    @Default("") String description,
    User? customerUser,
    User? vendorUser,
    User? employeeUser,
    Decimal? rate,
    DateTime? startDate,
    DateTime? endDate,
    Decimal? unInvoicedHours,
    @Default([]) List<TimeEntry> timeEntries,
    // from workflow editor
    @Default("") String jsonImage,
    @Default([]) List<Task> workflowTasks,
    // workflow task link to the view
    String? routing,
    String? flowElementId,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) =>
      _$TaskFromJson(json['task'] ?? json);

  @override
  List<Object?> get props => [taskId];

  @override
  String toString() => 'Task $taskName [$taskId]';
}
