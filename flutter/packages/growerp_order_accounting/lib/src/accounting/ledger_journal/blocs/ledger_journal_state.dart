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

part of 'ledger_journal_bloc.dart';

enum LedgerJournalStatus { initial, success, failure }

class LedgerJournalState extends Equatable {
  const LedgerJournalState({
    this.status = LedgerJournalStatus.initial,
    this.ledgerJournals = const <LedgerJournal>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final LedgerJournalStatus status;
  final String? message;
  final List<LedgerJournal> ledgerJournals;
  final bool hasReachedMax;
  final String searchString;

  LedgerJournalState copyWith({
    LedgerJournalStatus? status,
    String? message,
    List<LedgerJournal>? ledgerJournals,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return LedgerJournalState(
      status: status ?? this.status,
      ledgerJournals: ledgerJournals ?? this.ledgerJournals,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [message, ledgerJournals, hasReachedMax];

  @override
  String toString() => '$status { #ledgerJournals: ${ledgerJournals.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
