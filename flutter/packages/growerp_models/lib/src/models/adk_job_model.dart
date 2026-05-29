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
