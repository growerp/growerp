/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
