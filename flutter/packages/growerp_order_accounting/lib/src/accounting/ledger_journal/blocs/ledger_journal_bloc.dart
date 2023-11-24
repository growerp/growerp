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
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'ledger_journal_event.dart';
part 'ledger_journal_state.dart';

const _ledgerJournalLimit = 20;

EventTransformer<E> ledgerJournalDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LedgerJournalBloc extends Bloc<LedgerJournalEvent, LedgerJournalState> {
  LedgerJournalBloc(this.restClient) : super(const LedgerJournalState()) {
    on<LedgerJournalFetch>(_onLedgerJournalFetch,
        transformer: ledgerJournalDroppable(const Duration(milliseconds: 100)));
    on<LedgerJournalUpdate>(_onLedgerJournalUpdate);
  }

  final RestClient restClient;
  late int start;

  Future<void> _onLedgerJournalFetch(
    LedgerJournalFetch event,
    Emitter<LedgerJournalState> emit,
  ) async {
    if (state.status == LedgerJournalStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.ledgerJournals.length;
    }
    try {
      LedgerJournals result = await restClient.getLedgerJournal(
          start: start, searchString: event.searchString, limit: event.limit);
      return emit(state.copyWith(
        status: LedgerJournalStatus.success,
        ledgerJournals: start == 0
            ? result.ledgerJournals
            : (List.of(state.ledgerJournals)..addAll(result.ledgerJournals)),
        hasReachedMax:
            result.ledgerJournals.length < _ledgerJournalLimit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LedgerJournalStatus.failure,
          ledgerJournals: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onLedgerJournalUpdate(
    LedgerJournalUpdate event,
    Emitter<LedgerJournalState> emit,
  ) async {
    try {
      List<LedgerJournal> ledgerJournals = List.from(state.ledgerJournals);
      if (event.ledgerJournal.journalId.isNotEmpty) {
        LedgerJournal compResult = await restClient.updateLedgerJournal(
            ledgerJournal: event.ledgerJournal);
        int index = ledgerJournals.indexWhere(
            (element) => element.journalId == event.ledgerJournal.journalId);
        ledgerJournals[index] = compResult;
        return emit(state.copyWith(
            status: LedgerJournalStatus.success,
            ledgerJournals: ledgerJournals,
            message:
                "ledgerJournal ${event.ledgerJournal.journalName} updated"));
      } else {
        // add
        LedgerJournal compResult = await restClient.createLedgerJournal(
            ledgerJournal: event.ledgerJournal);
        ledgerJournals.insert(0, compResult);
        return emit(state.copyWith(
            status: LedgerJournalStatus.success,
            ledgerJournals: ledgerJournals,
            message: "ledgerJournal ${event.ledgerJournal.journalName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LedgerJournalStatus.failure,
          ledgerJournals: [],
          message: getDioError(e)));
    }
  }
}
