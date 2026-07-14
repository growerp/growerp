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

part 'ledger_dashboard_model.freezed.dart';
part 'ledger_dashboard_model.g.dart';

@freezed
abstract class LedgerStageSummaryItem with _$LedgerStageSummaryItem {
  LedgerStageSummaryItem._();
  factory LedgerStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _LedgerStageSummaryItem;

  factory LedgerStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$LedgerStageSummaryItemFromJson(json);
}

@freezed
abstract class LedgerDashboard with _$LedgerDashboard {
  LedgerDashboard._();
  factory LedgerDashboard({
    @Default([]) List<LedgerStageSummaryItem> stageSummary,
    @Default(0) int accounts,
    @Default(0) int posted,
    @Default(0) int unposted,
    @Default(0) int totalTransactions,
  }) = _LedgerDashboard;

  factory LedgerDashboard.fromJson(Map<String, dynamic> json) =>
      _$LedgerDashboardFromJson(json);
}
