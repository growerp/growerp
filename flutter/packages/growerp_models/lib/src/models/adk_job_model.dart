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

import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';

part 'adk_job_model.g.dart';

@JsonSerializable()
class AdkJob {
  final String jobName;
  final String agentName;
  final String? configId;
  final String? cronExpression;
  final bool paused;
  final bool isLocked;
  final String? lockRunId;
  @DateTimeConverter()
  final DateTime? lastRunTime;
  final int lockAgeMin;
  final String latestStatus;
  @DateTimeConverter()
  final DateTime? latestStart;
  @DateTimeConverter()
  final DateTime? latestEnd;
  final String? latestErrors;

  const AdkJob({
    required this.jobName,
    required this.agentName,
    this.configId,
    this.cronExpression,
    required this.paused,
    required this.isLocked,
    this.lockRunId,
    this.lastRunTime,
    required this.lockAgeMin,
    required this.latestStatus,
    this.latestStart,
    this.latestEnd,
    this.latestErrors,
  });

  factory AdkJob.fromJson(Map<String, dynamic> json) => _$AdkJobFromJson(json);
  Map<String, dynamic> toJson() => _$AdkJobToJson(this);
}

@JsonSerializable()
class AdkJobs {
  final List<AdkJob> adkJobs;

  const AdkJobs({required this.adkJobs});

  factory AdkJobs.fromJson(Map<String, dynamic> json) =>
      _$AdkJobsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkJobsToJson(this);
}
