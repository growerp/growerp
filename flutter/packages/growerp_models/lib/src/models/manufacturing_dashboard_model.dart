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

part 'manufacturing_dashboard_model.freezed.dart';
part 'manufacturing_dashboard_model.g.dart';

@freezed
abstract class ManufacturingStageSummaryItem
    with _$ManufacturingStageSummaryItem {
  ManufacturingStageSummaryItem._();
  factory ManufacturingStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _ManufacturingStageSummaryItem;

  factory ManufacturingStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingStageSummaryItemFromJson(json);
}

@freezed
abstract class ManufacturingDashboard with _$ManufacturingDashboard {
  ManufacturingDashboard._();
  factory ManufacturingDashboard({
    @Default([]) List<ManufacturingStageSummaryItem> stageSummary,
    @Default(0) int totalWorkOrders,
    @Default(0) int onHold,
    @Default(0) int cancelled,
    @Default(0) int bomItems,
  }) = _ManufacturingDashboard;

  factory ManufacturingDashboard.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingDashboardFromJson(json);
}
