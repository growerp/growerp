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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'infra_metrics_model.freezed.dart';
part 'infra_metrics_model.g.dart';

@freezed
abstract class InfraHost with _$InfraHost {
  InfraHost._();
  factory InfraHost({
    @Default(0) double cpuPercent,
    @Default(0) double load1,
    @Default(0) double memUsedBytes,
    @Default(0) double memTotalBytes,
    @Default(0) double diskUsedBytes,
    @Default(0) double diskTotalBytes,
    @Default(0) double uptimeSeconds,
  }) = _InfraHost;

  factory InfraHost.fromJson(Map<String, dynamic> json) =>
      _$InfraHostFromJson(json);
}

@freezed
abstract class InfraJvm with _$InfraJvm {
  InfraJvm._();
  factory InfraJvm({
    @Default("") String instance,
    @Default(0) double heapUsedBytes,
    @Default(0) double heapMaxBytes,
    @Default(0) double heapCommittedBytes,
    @Default(0) double nonHeapUsedBytes,
    @Default(0) double threadCount,
    @Default(0) double gcTimeSeconds,
  }) = _InfraJvm;

  factory InfraJvm.fromJson(Map<String, dynamic> json) =>
      _$InfraJvmFromJson(json);
}

@freezed
abstract class InfraDatabaseEntry with _$InfraDatabaseEntry {
  InfraDatabaseEntry._();
  factory InfraDatabaseEntry({
    @Default("") String name,
    @Default(0) double connections,
    @Default(0) double sizeBytes,
  }) = _InfraDatabaseEntry;

  factory InfraDatabaseEntry.fromJson(Map<String, dynamic> json) =>
      _$InfraDatabaseEntryFromJson(json);
}

@freezed
abstract class InfraDatabase with _$InfraDatabase {
  InfraDatabase._();
  factory InfraDatabase({
    @Default(0) double connections,
    @Default(0) double maxConnections,
    @Default([]) List<InfraDatabaseEntry> databases,
  }) = _InfraDatabase;

  factory InfraDatabase.fromJson(Map<String, dynamic> json) =>
      _$InfraDatabaseFromJson(json);
}

@freezed
abstract class InfraVhost with _$InfraVhost {
  InfraVhost._();
  factory InfraVhost({
    @Default("") String host,
    @Default(0) double requestsPerSecond,
    @Default(0) double error5xxPerSecond,
  }) = _InfraVhost;

  factory InfraVhost.fromJson(Map<String, dynamic> json) =>
      _$InfraVhostFromJson(json);
}

@freezed
abstract class InfraNginx with _$InfraNginx {
  InfraNginx._();
  factory InfraNginx({
    @Default(0) double activeConnections,
    @Default(0) double requestsPerSecond,
    @Default(0) double droppedConnections,
    @Default([]) List<InfraVhost> vhosts,
  }) = _InfraNginx;

  factory InfraNginx.fromJson(Map<String, dynamic> json) =>
      _$InfraNginxFromJson(json);
}

@freezed
abstract class InfraContainer with _$InfraContainer {
  InfraContainer._();
  factory InfraContainer({
    @Default("") String service,
    @Default(0) int taskCount,
    @Default(0) double cpuPercent,
    @Default(0) double memUsedBytes,
    @Default(0) double memLimitBytes,
  }) = _InfraContainer;

  factory InfraContainer.fromJson(Map<String, dynamic> json) =>
      _$InfraContainerFromJson(json);
}

@freezed
abstract class InfraMetrics with _$InfraMetrics {
  InfraMetrics._();
  factory InfraMetrics({
    @Default(false) bool available,
    @Default("") String message,
    InfraHost? host,
    @Default([]) List<InfraJvm> jvms,
    InfraDatabase? database,
    InfraNginx? nginx,
    @Default([]) List<InfraContainer> containers,
  }) = _InfraMetrics;

  factory InfraMetrics.fromJson(Map<String, dynamic> json) =>
      _$InfraMetricsFromJson(json);
}
