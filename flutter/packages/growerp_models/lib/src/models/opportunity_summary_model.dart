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
