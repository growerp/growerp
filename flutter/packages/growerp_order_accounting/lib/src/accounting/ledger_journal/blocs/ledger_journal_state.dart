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
  String toString() =>
      '$status { #ledgerJournals: ${ledgerJournals.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
