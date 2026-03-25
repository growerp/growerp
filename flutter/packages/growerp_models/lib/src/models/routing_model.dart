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

part 'routing_model.freezed.dart';
part 'routing_model.g.dart';

@freezed
abstract class RoutingTask with _$RoutingTask {
  factory RoutingTask({
    @Default("") String routingTaskId,
    @Default("") String routingId,
    String? taskName,
    int? sequenceNum,
    Decimal? estimatedWorkTime,
    String? workCenterName,
  }) = _RoutingTask;
  RoutingTask._();

  factory RoutingTask.fromJson(Map<String, dynamic> json) =>
      _$RoutingTaskFromJson(json['routingTask'] ?? json);

  @override
  String toString() =>
      'RoutingTask: $sequenceNum $taskName workCenter: $workCenterName';
}

@freezed
abstract class Routing with _$Routing {
  factory Routing({
    @Default("") String routingId,
    String? routingName,
    String? description,
    @Default([]) List<RoutingTask> routingTasks,
  }) = _Routing;
  Routing._();

  factory Routing.fromJson(Map<String, dynamic> json) =>
      _$RoutingFromJson(json['routing'] ?? json);

  @override
  String toString() => 'Routing: $routingId ($routingName)';
}
