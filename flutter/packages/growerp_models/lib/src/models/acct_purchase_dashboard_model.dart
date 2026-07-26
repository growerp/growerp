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
