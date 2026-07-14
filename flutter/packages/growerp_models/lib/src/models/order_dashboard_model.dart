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
