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
import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';
import 'models.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class Task with _$Task {
  Task._();
  factory Task({
    String? taskId,
    String? parentTaskId,
    String? statusId,
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
