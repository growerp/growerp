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

part 'acct_purchase_dashboard_model.freezed.dart';
part 'acct_purchase_dashboard_model.g.dart';

@freezed
abstract class AcctPurchaseStageSummaryItem with _$AcctPurchaseStageSummaryItem {
  AcctPurchaseStageSummaryItem._();
  factory AcctPurchaseStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _AcctPurchaseStageSummaryItem;

  factory AcctPurchaseStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$AcctPurchaseStageSummaryItemFromJson(json);
}

@freezed
abstract class AcctPurchaseDashboard with _$AcctPurchaseDashboard {
  AcctPurchaseDashboard._();
  factory AcctPurchaseDashboard({
    @Default([]) List<AcctPurchaseStageSummaryItem> stageSummary,
    @Default(0) int totalInvoices,
    @Default(0) int unpaidInvoices,
    @Default(0) int paidInvoices,
    @Default(0) int cancelledInvoices,
  }) = _AcctPurchaseDashboard;

  factory AcctPurchaseDashboard.fromJson(Map<String, dynamic> json) =>
      _$AcctPurchaseDashboardFromJson(json);
}
