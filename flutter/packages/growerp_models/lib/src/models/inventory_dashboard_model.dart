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
