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
