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

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_rest/growerp_rest.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../accounting.dart';

part 'ledger_journal_event.dart';
part 'ledger_journal_state.dart';

const _ledgerJournalLimit = 20;

EventTransformer<E> ledgerJournalDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LedgerJournalBloc extends Bloc<LedgerJournalEvent, LedgerJournalState> {
  LedgerJournalBloc(this.repos) : super(const LedgerJournalState()) {
    on<LedgerJournalFetch>(_onLedgerJournalFetch,
        transformer: ledgerJournalDroppable(const Duration(milliseconds: 100)));
    on<LedgerJournalUpdate>(_onLedgerJournalUpdate);
  }

  final AccountingAPIRepository repos;
  Future<void> _onLedgerJournalFetch(
    LedgerJournalFetch event,
    Emitter<LedgerJournalState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    // start from record zero for initial and refresh
    if (state.status == LedgerJournalStatus.initial || event.refresh) {
      ApiResult<List<LedgerJournal>> compResult =
          await repos.getLedgerJournal(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: LedgerJournalStatus.success,
                ledgerJournals: data,
                hasReachedMax: data.length < _ledgerJournalLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: LedgerJournalStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<LedgerJournal>> compResult =
          await repos.getLedgerJournal(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: LedgerJournalStatus.success,
                ledgerJournals: data,
                hasReachedMax: data.length < _ledgerJournalLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: LedgerJournalStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search
    ApiResult<List<LedgerJournal>> compResult = await repos.getLedgerJournal(
        searchString: event.searchString,
        start: state.ledgerJournals.length,
        limit: _ledgerJournalLimit);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: LedgerJournalStatus.success,
              ledgerJournals: List.of(state.ledgerJournals)..addAll(data),
              hasReachedMax: data.length < _ledgerJournalLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: LedgerJournalStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onLedgerJournalUpdate(
    LedgerJournalUpdate event,
    Emitter<LedgerJournalState> emit,
  ) async {
    List<LedgerJournal> ledgerJournals = List.from(state.ledgerJournals);
    if (event.ledgerJournal.journalId.isNotEmpty) {
      ApiResult<LedgerJournal> compResult =
          await repos.updateLedgerJournal(event.ledgerJournal);
      return emit(compResult.when(
          success: (data) {
            int index = ledgerJournals.indexWhere((element) =>
                element.journalId == event.ledgerJournal.journalId);
            ledgerJournals[index] = data;
            return state.copyWith(
                status: LedgerJournalStatus.success,
                ledgerJournals: ledgerJournals,
                message:
                    "ledgerJournal ${event.ledgerJournal.journalName} updated");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: LedgerJournalStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<LedgerJournal> compResult =
          await repos.createLedgerJournal(event.ledgerJournal);
      return emit(compResult.when(
          success: (data) {
            ledgerJournals.insert(0, data);
            return state.copyWith(
                status: LedgerJournalStatus.success,
                ledgerJournals: ledgerJournals,
                message:
                    "ledgerJournal ${event.ledgerJournal.journalName} added");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: LedgerJournalStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }
}
