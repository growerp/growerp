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

part 'catalog_dashboard_model.freezed.dart';
part 'catalog_dashboard_model.g.dart';

@freezed
abstract class CatalogStageSummaryItem with _$CatalogStageSummaryItem {
  CatalogStageSummaryItem._();
  factory CatalogStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _CatalogStageSummaryItem;

  factory CatalogStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$CatalogStageSummaryItemFromJson(json);
}

@freezed
abstract class CatalogDashboard with _$CatalogDashboard {
  CatalogDashboard._();
  factory CatalogDashboard({
    @Default([]) List<CatalogStageSummaryItem> stageSummary,
    @Default(0) int categories,
    @Default(0) int activeProducts,
    @Default(0) int assets,
    @Default(0) int discontinuedProducts,
  }) = _CatalogDashboard;

  factory CatalogDashboard.fromJson(Map<String, dynamic> json) =>
      _$CatalogDashboardFromJson(json);
}
