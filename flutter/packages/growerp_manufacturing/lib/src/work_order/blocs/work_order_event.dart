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

abstract class WorkOrderEvent extends Equatable {
  const WorkOrderEvent();
  @override
  List<Object?> get props => [];
}

class WorkOrderFetch extends WorkOrderEvent {
  const WorkOrderFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object> get props => [searchString, refresh];
}

class WorkOrderUpdate extends WorkOrderEvent {
  const WorkOrderUpdate(this.workOrder);
  final WorkOrder workOrder;
}

class WorkOrderDelete extends WorkOrderEvent {
  const WorkOrderDelete(this.workOrder);
  final WorkOrder workOrder;
}
