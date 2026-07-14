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
