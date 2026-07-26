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

part 'ledger_journal_model.freezed.dart';
part 'ledger_journal_model.g.dart';

@freezed
abstract class LedgerJournal with _$LedgerJournal {
  LedgerJournal._();
  factory LedgerJournal({
    @Default('') String journalId,
    @Default('') String journalName,
    DateTime? postedDate,
    bool? isPosted,
    bool? isError,
  }) = _LedgerJournal;

  factory LedgerJournal.fromJson(Map<String, dynamic> json) =>
      _$LedgerJournalFromJson(json['ledgerJournal'] ?? json);
}
