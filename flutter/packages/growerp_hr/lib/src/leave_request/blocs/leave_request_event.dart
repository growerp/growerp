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

part of 'leave_request_bloc.dart';

abstract class LeaveRequestEvent extends Equatable {
  const LeaveRequestEvent();
  @override
  List<Object?> get props => [];
}

class LeaveRequestsFetch extends LeaveRequestEvent {
  const LeaveRequestsFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
    this.partyId,
    this.leaveStatus,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  final String? partyId;
  final LeaveStatus? leaveStatus;
  @override
  List<Object?> get props => [searchString, refresh, partyId, leaveStatus];
}

class LeaveRequestUpdate extends LeaveRequestEvent {
  const LeaveRequestUpdate(this.leaveRequest);
  final LeaveRequest leaveRequest;
}

class LeaveRequestDelete extends LeaveRequestEvent {
  const LeaveRequestDelete(this.leaveRequest);
  final LeaveRequest leaveRequest;
}

class LeaveBalancesFetch extends LeaveRequestEvent {
  const LeaveBalancesFetch({this.partyId, this.year});
  final String? partyId;
  final int? year;
  @override
  List<Object?> get props => [partyId, year];
}

class LeaveAllowanceUpdate extends LeaveRequestEvent {
  const LeaveAllowanceUpdate({
    required this.partyId,
    required this.leaveType,
    required this.year,
    required this.days,
  });
  final String partyId;
  final LeaveType leaveType;
  final int year;
  final Decimal days;
}

class LeaveRequestSearchChanged extends LeaveRequestEvent {
  const LeaveRequestSearchChanged({required this.searchString, this.partyId});
  final String searchString;
  final String? partyId;
  @override
  List<Object?> get props => [searchString, partyId];
}
