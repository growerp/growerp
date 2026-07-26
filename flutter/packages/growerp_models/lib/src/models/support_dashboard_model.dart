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

part 'support_dashboard_model.freezed.dart';
part 'support_dashboard_model.g.dart';

@freezed
abstract class SupportBarItem with _$SupportBarItem {
  SupportBarItem._();
  factory SupportBarItem({
    @Default("") String label,
    @Default(0) int count,
  }) = _SupportBarItem;

  factory SupportBarItem.fromJson(Map<String, dynamic> json) =>
      _$SupportBarItemFromJson(json);
}

@freezed
abstract class SupportApplicationsStats with _$SupportApplicationsStats {
  SupportApplicationsStats._();
  factory SupportApplicationsStats({
    @Default([]) List<SupportBarItem> bars,
    @Default(0) int applications,
    @Default(0) int installs,
    @Default(0) int withAssessment,
    @Default(0) int withoutAssessment,
  }) = _SupportApplicationsStats;

  factory SupportApplicationsStats.fromJson(Map<String, dynamic> json) =>
      _$SupportApplicationsStatsFromJson(json);
}

@freezed
abstract class SupportOwnersStats with _$SupportOwnersStats {
  SupportOwnersStats._();
  factory SupportOwnersStats({
    @Default([]) List<SupportBarItem> bars,
    @Default(0) int owners,
    @Default(0) int active,
    @Default(0) int users,
    @Default(0) int companies,
  }) = _SupportOwnersStats;

  factory SupportOwnersStats.fromJson(Map<String, dynamic> json) =>
      _$SupportOwnersStatsFromJson(json);
}

@freezed
abstract class SupportLlmUsageStats with _$SupportLlmUsageStats {
  SupportLlmUsageStats._();
  factory SupportLlmUsageStats({
    @Default([]) List<SupportBarItem> bars,
    @Default(0) int tenants,
    @Default(0) int actions,
    @Default(0) int tokensIn,
    @Default(0) int tokensOut,
  }) = _SupportLlmUsageStats;

  factory SupportLlmUsageStats.fromJson(Map<String, dynamic> json) =>
      _$SupportLlmUsageStatsFromJson(json);
}

@freezed
abstract class SupportRestUsageStats with _$SupportRestUsageStats {
  SupportRestUsageStats._();
  factory SupportRestUsageStats({
    @Default([]) List<SupportBarItem> bars,
    @Default(0) int users,
    @Default(0) int calls,
    @Default(0) int avgPerDay,
    @Default(0) int peakDay,
  }) = _SupportRestUsageStats;

  factory SupportRestUsageStats.fromJson(Map<String, dynamic> json) =>
      _$SupportRestUsageStatsFromJson(json);
}

@freezed
abstract class SupportDashboard with _$SupportDashboard {
  SupportDashboard._();
  factory SupportDashboard({
    SupportApplicationsStats? applications,
    SupportOwnersStats? owners,
    SupportLlmUsageStats? llmUsage,
    SupportRestUsageStats? restUsage,
  }) = _SupportDashboard;

  factory SupportDashboard.fromJson(Map<String, dynamic> json) =>
      _$SupportDashboardFromJson(json);
}
