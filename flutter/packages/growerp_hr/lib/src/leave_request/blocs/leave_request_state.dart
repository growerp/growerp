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

enum LeaveRequestStatus { initial, loading, success, balancesSuccess, failure }

class LeaveRequestState extends Equatable {
  const LeaveRequestState({
    this.status = LeaveRequestStatus.initial,
    this.leaveRequests = const <LeaveRequest>[],
    this.balances = const <LeaveBalance>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final LeaveRequestStatus status;
  final String? message;
  final List<LeaveRequest> leaveRequests;
  final List<LeaveBalance> balances;
  final bool hasReachedMax;
  final String searchString;

  LeaveRequestState copyWith({
    LeaveRequestStatus? status,
    String? message,
    List<LeaveRequest>? leaveRequests,
    List<LeaveBalance>? balances,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return LeaveRequestState(
      status: status ?? this.status,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      balances: balances ?? this.balances,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [leaveRequests, balances, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #leaveRequests: ${leaveRequests.length}, '
      '#balances: ${balances.length}, message: $message }';
}
