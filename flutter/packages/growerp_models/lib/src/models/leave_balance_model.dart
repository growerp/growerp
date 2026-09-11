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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../growerp_models.dart';

part 'leave_balance_model.freezed.dart';
part 'leave_balance_model.g.dart';

/// Leave allowance, used and remaining days of one employee, type and year.
@freezed
abstract class LeaveBalance with _$LeaveBalance {
  factory LeaveBalance({
    @Default("") String partyId,
    @JsonKey(name: 'leaveTypeEnumId')
    @LeaveTypeConverter()
    LeaveType? leaveType,
    @Default(0) int year,
    Decimal? allowance,
    Decimal? used,
    Decimal? remaining,
  }) = _LeaveBalance;
  LeaveBalance._();

  factory LeaveBalance.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceFromJson(json['leaveBalance'] ?? json);

  @override
  String toString() =>
      'LeaveBalance: $partyId $leaveType $year '
      '$used/$allowance';
}
