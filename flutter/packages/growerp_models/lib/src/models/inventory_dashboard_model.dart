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

part 'inventory_dashboard_model.freezed.dart';
part 'inventory_dashboard_model.g.dart';

@freezed
abstract class InventoryStageSummaryItem with _$InventoryStageSummaryItem {
  InventoryStageSummaryItem._();
  factory InventoryStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _InventoryStageSummaryItem;

  factory InventoryStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryStageSummaryItemFromJson(json);
}

@freezed
abstract class InventoryDashboard with _$InventoryDashboard {
  InventoryDashboard._();
  factory InventoryDashboard({
    @Default([]) List<InventoryStageSummaryItem> stageSummary,
    @Default(0) int whLocations,
    @Default(0) int incomingShipments,
    @Default(0) int outgoingShipments,
    @Default(0) int totalShipments,
  }) = _InventoryDashboard;

  factory InventoryDashboard.fromJson(Map<String, dynamic> json) =>
      _$InventoryDashboardFromJson(json);
}
