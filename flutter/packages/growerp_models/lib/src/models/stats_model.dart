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

part 'stats_model.freezed.dart';
part 'stats_model.g.dart';

@freezed
abstract class Stats with _$Stats {
  Stats._();
  factory Stats({
    @Default(0) int admins,
    @Default(0) int employees,
    @Default(0) int suppliers,
    @Default(0) int leads,
    @Default(0) int customers,
    @Default(0) int openSlsOrders,
    @Default(0) int openPurOrders,
    @Default(0) int opportunities,
    @Default(0) int myOpportunities,
    @Default(0) int categories,
    @Default(0) int products,
    @Default(0) int assets,
    @Default(0) int salesInvoicesNotPaidCount,
    Decimal? salesInvoicesNotPaidAmount,
    @Default(0) int purchInvoicesNotPaidCount,
    Decimal? purchInvoicesNotPaidAmount,
    @Default(0) int allTasks,
    @Default(0) int notInvoicedHours,
    @Default(0) int incomingShipments,
    @Default(0) int outgoingShipments,
    @Default(0) int whLocations,
    @Default(0) int requests,
    @Default(0) int todoActivities,
    @Default(0) int eventActivities,
  }) = _Stats;

  factory Stats.fromJson(Map<String, dynamic> json) =>
      _$StatsFromJson(json['stats'] ?? json);
}
