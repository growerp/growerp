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

part 'time_period_model.freezed.dart';
part 'time_period_model.g.dart';

@freezed
abstract class TimePeriod with _$TimePeriod {
  TimePeriod._();
  factory TimePeriod({
    @Default('') String periodId,
    @Default('') String periodName,
    @Default('') String periodType, // Y/M/Q
    DateTime? fromDate,
    DateTime? thruDate,
    @Default(false) bool hasPreviousPeriod,
    @Default(false) bool hasNextPeriod,
    @Default(false) bool isClosed,
  }) = _TimePeriod;

  factory TimePeriod.fromJson(Map<String, dynamic> json) =>
      _$TimePeriodFromJson(json['timePeriod'] ?? json);
}
