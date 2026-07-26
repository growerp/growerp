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
