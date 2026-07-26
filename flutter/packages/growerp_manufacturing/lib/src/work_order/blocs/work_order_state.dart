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

part of 'work_order_bloc.dart';

enum WorkOrderStatus { initial, loading, success, failure }

class WorkOrderState extends Equatable {
  const WorkOrderState({
    this.status = WorkOrderStatus.initial,
    this.workOrders = const <WorkOrder>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final WorkOrderStatus status;
  final String? message;
  final List<WorkOrder> workOrders;
  final bool hasReachedMax;
  final String searchString;

  WorkOrderState copyWith({
    WorkOrderStatus? status,
    String? message,
    List<WorkOrder>? workOrders,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return WorkOrderState(
      status: status ?? this.status,
      workOrders: workOrders ?? this.workOrders,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [workOrders, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #workOrders: ${workOrders.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
