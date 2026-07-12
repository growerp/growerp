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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'opportunity_summary_model.freezed.dart';
part 'opportunity_summary_model.g.dart';

@freezed
abstract class OpportunitySummaryItem with _$OpportunitySummaryItem {
  OpportunitySummaryItem._();
  factory OpportunitySummaryItem({
    @Default("") String stageId,
    int? sequenceNum,
    @Default(0) int opportunityCount,
    Decimal? totalAmount,
    Decimal? weightedAmount,
  }) = _OpportunitySummaryItem;

  factory OpportunitySummaryItem.fromJson(Map<String, dynamic> json) =>
      _$OpportunitySummaryItemFromJson(json['stage'] ?? json);
}

@freezed
abstract class OpportunitySummary with _$OpportunitySummary {
  OpportunitySummary._();
  factory OpportunitySummary({
    @Default([]) List<OpportunitySummaryItem> stageSummary,
  }) = _OpportunitySummary;

  factory OpportunitySummary.fromJson(Map<String, dynamic> json) =>
      _$OpportunitySummaryFromJson(json);
}
