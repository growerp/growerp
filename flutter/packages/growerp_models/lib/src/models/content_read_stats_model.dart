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
import 'package:growerp_models/growerp_models.dart';

part 'content_read_stats_model.freezed.dart';
part 'content_read_stats_model.g.dart';

/// Website visits from one platform's tagged link to a content piece.
/// [landings] counts every visit (bots and link previews included),
/// [reads] only the visits that were really read (visible dwell + scroll).
@freezed
abstract class ContentReadPlatform with _$ContentReadPlatform {
  ContentReadPlatform._();
  factory ContentReadPlatform({
    @Default("") String platform,
    @Default(0) int landings,
    @Default(0) int uniqueVisitors,
    @Default(0) int reads,
    @Default(0) int avgDwellSeconds,
  }) = _ContentReadPlatform;

  factory ContentReadPlatform.fromJson(Map<String, dynamic> json) =>
      _$ContentReadPlatformFromJson(json);
}

/// Website reads of one master content piece (utm_campaign = its pseudoId).
@freezed
abstract class ContentReadStats with _$ContentReadStats {
  ContentReadStats._();
  factory ContentReadStats({
    @Default("") String campaign,
    String? masterContentId,
    String? title,
    @Default(0) int landings,
    @Default(0) int uniqueVisitors,
    @Default(0) int reads,
    @Default(0) int readRate,
    @Default(0) int avgDwellSeconds,
    @NullableTimestampConverter() DateTime? lastLandedDate,
    @Default([]) List<ContentReadPlatform> platforms,
  }) = _ContentReadStats;

  factory ContentReadStats.fromJson(Map<String, dynamic> json) =>
      _$ContentReadStatsFromJson(json);
}

@freezed
abstract class ContentReadStatsResult with _$ContentReadStatsResult {
  ContentReadStatsResult._();
  factory ContentReadStatsResult({
    @Default([]) List<ContentReadStats> contentReadStats,
  }) = _ContentReadStatsResult;

  factory ContentReadStatsResult.fromJson(Map<String, dynamic> json) =>
      _$ContentReadStatsResultFromJson(json);
}
