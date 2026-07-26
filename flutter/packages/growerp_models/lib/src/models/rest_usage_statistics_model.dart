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
