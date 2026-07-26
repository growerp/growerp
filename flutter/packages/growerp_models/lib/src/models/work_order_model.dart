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

part 'work_order_model.freezed.dart';
part 'work_order_model.g.dart';

@freezed
abstract class WorkOrder with _$WorkOrder {
  factory WorkOrder({
    @Default("") String workEffortId,
    @Default("") String pseudoId,
    String? workEffortName,
    @JsonKey(name: 'statusId')
    @WorkOrderStatusValConverter()
    WorkOrderStatusVal? status,
    @Default("") String productId,
    String? productPseudoId,
    String? productName,
    Decimal? estimatedQuantity,
    String? estimatedStartDate,
    String? estimatedCompletionDate,
    String? actualStartDate,
    String? actualCompletionDate,
    Decimal? totalCost,
    String? routingId,
    String? routingName,
    @Default([]) List<BomItem> bomItems,
    @Default([]) List<LinerPanel> linerPanels,
  }) = _WorkOrder;
  WorkOrder._();

  factory WorkOrder.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderFromJson(json['workOrder'] ?? json);

  @override
  String toString() =>
      'WorkOrder: $pseudoId product: $productName qty: $estimatedQuantity '
      'status: $status';
}
