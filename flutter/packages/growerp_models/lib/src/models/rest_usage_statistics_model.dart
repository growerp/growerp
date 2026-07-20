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

part 'rest_usage_statistics_model.freezed.dart';
part 'rest_usage_statistics_model.g.dart';

@freezed
abstract class RestUsageDay with _$RestUsageDay {
  RestUsageDay._();
  factory RestUsageDay({
    @Default("") String day, // yyyy-MM-dd
    @Default(0) int hitCount,
  }) = _RestUsageDay;

  factory RestUsageDay.fromJson(Map<String, dynamic> json) =>
      _$RestUsageDayFromJson(json);
}

@freezed
abstract class RestUsageUser with _$RestUsageUser {
  RestUsageUser._();
  factory RestUsageUser({
    @Default("") String userId,
    @Default("") String userPartyId,
    String? firstName,
    String? lastName,
    String? loginName,
    String? companyName,
    @Default(0) int totalHits,
    @Default([]) List<RestUsageDay> days,
  }) = _RestUsageUser;

  factory RestUsageUser.fromJson(Map<String, dynamic> json) =>
      _$RestUsageUserFromJson(json);
}

@freezed
abstract class RestUsageStatistics with _$RestUsageStatistics {
  RestUsageStatistics._();
  factory RestUsageStatistics({
    @Default("") String fromDate, // yyyy-MM-dd
    @Default("") String thruDate, // yyyy-MM-dd
    @Default([]) List<RestUsageUser> users,
  }) = _RestUsageStatistics;

  factory RestUsageStatistics.fromJson(Map<String, dynamic> json) =>
      _$RestUsageStatisticsFromJson(json);
}
