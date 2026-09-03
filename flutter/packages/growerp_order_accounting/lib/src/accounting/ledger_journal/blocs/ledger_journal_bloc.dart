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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
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

const _ledgerJournalSearchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<LedgerJournalSearchChanged> ledgerJournalSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_ledgerJournalSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class LedgerJournalBloc extends Bloc<LedgerJournalEvent, LedgerJournalState> {
  LedgerJournalBloc(this.restClient) : super(const LedgerJournalState()) {
    on<LedgerJournalFetch>(
      _onLedgerJournalFetch,
      transformer: ledgerJournalDroppable(const Duration(milliseconds: 100)),
    );
    on<LedgerJournalSearchChanged>(
      _onLedgerJournalSearchChanged,
      transformer: ledgerJournalSearchDebounce(),
    );
    on<LedgerJournalUpdate>(_onLedgerJournalUpdate);
  }

  final RestClient restClient;
  late int start;

  Future<void> _onLedgerJournalSearchChanged(
    LedgerJournalSearchChanged event,
    Emitter<LedgerJournalState> emit,
  ) async {
    return _onLedgerJournalFetch(
      LedgerJournalFetch(
        refresh: true,
        searchString: event.searchString,
        limit: event.limit,
      ),
      emit,
    );
  }

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
        start: start,
        searchString: event.searchString,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          status: LedgerJournalStatus.success,
          ledgerJournals: start == 0
              ? result.ledgerJournals
              : (List.of(state.ledgerJournals)..addAll(result.ledgerJournals)),
          hasReachedMax: result.ledgerJournals.length < _ledgerJournalLimit
              ? true
              : false,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerJournalStatus.failure,
          ledgerJournals: [],
          message: await getDioError(e),
        ),
      );
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
          ledgerJournal: event.ledgerJournal,
        );
        int index = ledgerJournals.indexWhere(
          (element) => element.journalId == event.ledgerJournal.journalId,
        );
        ledgerJournals[index] = compResult;
        return emit(
          state.copyWith(
            status: LedgerJournalStatus.success,
            ledgerJournals: ledgerJournals,
            message: 'ledgerJournalUpdateSuccess',
          ),
        );
      } else {
        // add
        LedgerJournal compResult = await restClient.createLedgerJournal(
          ledgerJournal: event.ledgerJournal,
        );
        ledgerJournals.insert(0, compResult);
        return emit(
          state.copyWith(
            status: LedgerJournalStatus.success,
            ledgerJournals: ledgerJournals,
            message:
                'ledgerJournalAddSuccess:${event.ledgerJournal.journalName}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerJournalStatus.failure,
          ledgerJournals: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
