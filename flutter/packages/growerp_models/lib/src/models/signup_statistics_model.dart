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

part 'signup_statistics_model.freezed.dart';
part 'signup_statistics_model.g.dart';

/// A new tenant registration that logged in at least once. Login and REST
/// figures come from the artifact hit log, which is purged after 90 days.
@freezed
abstract class Signup with _$Signup {
  Signup._();
  factory Signup({
    @Default("") String ownerPartyId,
    @Default("") String companyName,
    @Default("") String adminName,
    @Default("") String adminEmail,
    @Default("") String applicationId,
    @Default("") String signupDate, // yyyy-MM-dd
    @Default("") String firstLoginDate, // yyyy-MM-dd
    @Default("") String lastLoginDate, // yyyy-MM-dd
    @Default(0) int daysLoggedIn,
    @Default(0) int loginCount,
    @Default(0) int restCalls,
    @Default(0) int userCount,
    @Default([]) List<String> appsUsed,
  }) = _Signup;

  factory Signup.fromJson(Map<String, dynamic> json) => _$SignupFromJson(json);
}

@freezed
abstract class SignupStatistics with _$SignupStatistics {
  SignupStatistics._();
  factory SignupStatistics({
    @Default("") String fromDate, // yyyy-MM-dd
    @Default("") String thruDate, // yyyy-MM-dd
    @Default(0) int signupCount, // matching rows before paging
    @Default([]) List<Signup> signups,
  }) = _SignupStatistics;

  factory SignupStatistics.fromJson(Map<String, dynamic> json) =>
      _$SignupStatisticsFromJson(json);
}
