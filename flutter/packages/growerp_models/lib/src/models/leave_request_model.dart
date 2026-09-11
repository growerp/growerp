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

part 'leave_request_model.freezed.dart';
part 'leave_request_model.g.dart';

@freezed
abstract class LeaveRequest with _$LeaveRequest {
  factory LeaveRequest({
    @Default("") String leaveRequestId,
    @Default("") String pseudoId,
    @Default("") String partyId,
    String? employeeName,
    @JsonKey(name: 'leaveTypeEnumId')
    @LeaveTypeConverter()
    LeaveType? leaveType,
    @DateTimeConverter() DateTime? fromDate,
    @DateTimeConverter() DateTime? thruDate,
    Decimal? days,
    @JsonKey(name: 'statusId') @LeaveStatusConverter() LeaveStatus? status,
    String? reason,
    String? comments,
    String? approverPartyId,
  }) = _LeaveRequest;
  LeaveRequest._();

  factory LeaveRequest.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestFromJson(json['leaveRequest'] ?? json);

  @override
  String toString() =>
      'LeaveRequest: $pseudoId $partyId $leaveType $days days $status';
}
