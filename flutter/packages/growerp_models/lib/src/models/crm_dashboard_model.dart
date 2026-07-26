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

part 'crm_dashboard_model.freezed.dart';
part 'crm_dashboard_model.g.dart';

@freezed
abstract class CrmStageSummaryItem with _$CrmStageSummaryItem {
  CrmStageSummaryItem._();
  factory CrmStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _CrmStageSummaryItem;

  factory CrmStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$CrmStageSummaryItemFromJson(json);
}

@freezed
abstract class CrmDashboard with _$CrmDashboard {
  CrmDashboard._();
  factory CrmDashboard({
    @Default([]) List<CrmStageSummaryItem> stageSummary,
    @Default(0) int suppliers,
    @Default(0) int employees,
    @Default(0) int admins,
    @Default(0) int totalContacts,
  }) = _CrmDashboard;

  factory CrmDashboard.fromJson(Map<String, dynamic> json) =>
      _$CrmDashboardFromJson(json);
}
