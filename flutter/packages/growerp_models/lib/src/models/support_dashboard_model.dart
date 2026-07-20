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
