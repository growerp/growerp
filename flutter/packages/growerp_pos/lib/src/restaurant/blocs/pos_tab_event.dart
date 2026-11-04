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

part of 'pos_tab_bloc.dart';

abstract class PosTabEvent extends Equatable {
  const PosTabEvent();
  @override
  List<Object?> get props => [];
}

/// the tab with this id, else a new one at the table
class PosTabOpen extends PosTabEvent {
  const PosTabOpen({this.tabId, this.tableAssetId});
  final String? tabId;
  final String? tableAssetId;
  @override
  List<Object?> get props => [tabId, tableAssetId];
}

class PosTabAddLine extends PosTabEvent {
  const PosTabAddLine(this.productId, {this.modifierIds, this.note});
  final String productId;
  final List<String>? modifierIds;
  final String? note;
  @override
  List<Object?> get props => [productId, modifierIds, note];
}

class PosTabChangeLine extends PosTabEvent {
  const PosTabChangeLine(this.orderItemSeqId, this.quantity);
  final String orderItemSeqId;
  final Decimal quantity;
  @override
  List<Object?> get props => [orderItemSeqId, quantity];
}

class PosTabVoidLine extends PosTabEvent {
  const PosTabVoidLine(this.orderItemSeqId, {this.reason});
  final String orderItemSeqId;
  final String? reason;
  @override
  List<Object?> get props => [orderItemSeqId, reason];
}

class PosTabSend extends PosTabEvent {
  const PosTabSend();
}

class PosTabMove extends PosTabEvent {
  const PosTabMove(this.tableAssetId);
  final String tableAssetId;
  @override
  List<Object?> get props => [tableAssetId];
}

/// equal with ways, by item with assignments
class PosTabSplit extends PosTabEvent {
  const PosTabSplit({this.ways, this.assignments});
  final int? ways;
  final List<PosSplitAssignment>? assignments;
  @override
  List<Object?> get props => [ways, assignments];
}

class PosTabCancel extends PosTabEvent {
  const PosTabCancel();
}
