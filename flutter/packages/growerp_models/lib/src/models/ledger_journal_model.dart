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
