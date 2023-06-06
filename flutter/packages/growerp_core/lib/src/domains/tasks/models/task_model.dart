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

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../services/json_converters.dart';
import '../../domains.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

Task taskFromJson(String str) => Task.fromJson(json.decode(str)["task"]);
// ignore: prefer_interpolation_to_compose_strings
String taskToJson(Task data) => '{"task":' + json.encode(data.toJson()) + "}";

List<Task> tasksFromJson(String str) =>
    List<Task>.from(json.decode(str)["taskList"].map((x) => Task.fromJson(x)));

@freezed
class Task with _$Task {
  Task._();
  factory Task({
    String? taskId,
    String? parentTaskId,
    String? status,
    String? taskName,
    String? description,
    User? customerUser,
    User? vendorUser,
    User? employeeUser,
    Decimal? rate,
    @DateTimeConverter() DateTime? startDate,
    @DateTimeConverter() DateTime? endDate,
    Decimal? unInvoicedHours,
    @Default([]) List<TimeEntry> timeEntries,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  @override
  String toString() => 'Task $taskName [$taskId]';
}
