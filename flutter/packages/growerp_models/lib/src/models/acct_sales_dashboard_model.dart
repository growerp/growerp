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

part 'acct_sales_dashboard_model.freezed.dart';
part 'acct_sales_dashboard_model.g.dart';

@freezed
abstract class AcctSalesStageSummaryItem with _$AcctSalesStageSummaryItem {
  AcctSalesStageSummaryItem._();
  factory AcctSalesStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _AcctSalesStageSummaryItem;

  factory AcctSalesStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$AcctSalesStageSummaryItemFromJson(json);
}

@freezed
abstract class AcctSalesDashboard with _$AcctSalesDashboard {
  AcctSalesDashboard._();
  factory AcctSalesDashboard({
    @Default([]) List<AcctSalesStageSummaryItem> stageSummary,
    @Default(0) int totalInvoices,
    @Default(0) int unpaidInvoices,
    @Default(0) int paidInvoices,
    @Default(0) int cancelledInvoices,
  }) = _AcctSalesDashboard;

  factory AcctSalesDashboard.fromJson(Map<String, dynamic> json) =>
      _$AcctSalesDashboardFromJson(json);
}
