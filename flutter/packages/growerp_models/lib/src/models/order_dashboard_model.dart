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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_dashboard_model.freezed.dart';
part 'order_dashboard_model.g.dart';

@freezed
abstract class OrderStageSummaryItem with _$OrderStageSummaryItem {
  OrderStageSummaryItem._();
  factory OrderStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _OrderStageSummaryItem;

  factory OrderStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$OrderStageSummaryItemFromJson(json);
}

@freezed
abstract class OrderDashboard with _$OrderDashboard {
  OrderDashboard._();
  factory OrderDashboard({
    @Default([]) List<OrderStageSummaryItem> stageSummary,
    @Default(0) int salesOrders,
    @Default(0) int purchaseOrders,
    @Default(0) int salesInvoicesNotPaidCount,
    @Default(0) int purchInvoicesNotPaidCount,
  }) = _OrderDashboard;

  factory OrderDashboard.fromJson(Map<String, dynamic> json) =>
      _$OrderDashboardFromJson(json);
}
