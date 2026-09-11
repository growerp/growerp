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
import 'models.dart';

part 'profit_loss_model.freezed.dart';
part 'profit_loss_model.g.dart';

/// Simple profit & loss statement for one period.
@freezed
abstract class ProfitLoss with _$ProfitLoss {
  ProfitLoss._();
  factory ProfitLoss({
    TimePeriod? period,
    @Default([]) List<ProfitLossLine> income,
    @Default([]) List<ProfitLossLine> expenses,
    Decimal? totalIncome,
    Decimal? totalExpenses,
    Decimal? netProfit,
  }) = _ProfitLoss;

  factory ProfitLoss.fromJson(Map<String, dynamic> json) =>
      _$ProfitLossFromJson(json['profitLoss'] ?? json);
}

@freezed
abstract class ProfitLossLine with _$ProfitLossLine {
  ProfitLossLine._();
  factory ProfitLossLine({
    @Default('') String glAccountId,
    @Default('') String accountCode,
    @Default('') String accountName,
    @Default('') String className,
    Decimal? amount,
  }) = _ProfitLossLine;

  factory ProfitLossLine.fromJson(Map<String, dynamic> json) =>
      _$ProfitLossLineFromJson(json);
}
