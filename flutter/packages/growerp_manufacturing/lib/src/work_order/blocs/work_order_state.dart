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
