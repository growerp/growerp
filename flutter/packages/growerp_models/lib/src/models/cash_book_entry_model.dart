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
import '../json_converters.dart';
import 'models.dart';

part 'cash_book_entry_model.freezed.dart';
part 'cash_book_entry_model.g.dart';

/// One line of the simplified cash book: money in (income) or out (expense),
/// stored as a posted ledger transaction against the cash & bank account.
@freezed
abstract class CashBookEntry with _$CashBookEntry {
  CashBookEntry._();
  factory CashBookEntry({
    String? transactionId,
    String? pseudoId,
    @DateTimeConverter() DateTime? date,
    @Default(true) bool isIncome,
    Decimal? amount,
    GlAccount? category, // income or expense ledger account
    @Default('') String description,
    Company? otherCompany,
    User? otherUser,
    // manual, invoice or payment: only manual entries can be changed here
    @Default('manual') String source,
    @Default(false) bool isPosted,
  }) = _CashBookEntry;

  factory CashBookEntry.fromJson(Map<String, dynamic> json) =>
      _$CashBookEntryFromJson(json['cashBookEntry'] ?? json);
}
