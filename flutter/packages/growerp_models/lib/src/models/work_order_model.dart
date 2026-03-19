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
    String? statusId,
    @Default("") String productId,
    String? productPseudoId,
    String? productName,
    Decimal? estimatedQuantity,
    String? estimatedStartDate,
    String? estimatedCompletionDate,
    String? actualStartDate,
    String? actualCompletionDate,
    Decimal? totalCost,
    @Default([]) List<BomItem> bomItems,
  }) = _WorkOrder;
  WorkOrder._();

  factory WorkOrder.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderFromJson(json['workOrder'] ?? json);

  @override
  String toString() =>
      'WorkOrder: $pseudoId product: $productName qty: $estimatedQuantity '
      'status: $statusId';
}
