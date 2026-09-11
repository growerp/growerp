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

part 'cash_book_event.dart';
part 'cash_book_state.dart';

const _cashBookLimit = 20;

EventTransformer<E> cashBookDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

const _cashBookSearchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<CashBookSearchChanged> cashBookSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_cashBookSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

/// Simplified cash in / cash out bookkeeping: the list of cash book entries
/// plus the income and expense categories (ledger accounts) they are booked on.
class CashBookBloc extends Bloc<CashBookEvent, CashBookState> {
  CashBookBloc(this.restClient) : super(const CashBookState()) {
    on<CashBookFetch>(
      _onCashBookFetch,
      transformer: cashBookDroppable(const Duration(milliseconds: 100)),
    );
    on<CashBookSearchChanged>(
      _onCashBookSearchChanged,
      transformer: cashBookSearchDebounce(),
    );
    on<CashBookUpdate>(_onCashBookUpdate);
    on<CashBookDelete>(_onCashBookDelete);
    on<CashBookCategoriesFetch>(_onCashBookCategoriesFetch);
  }

  final RestClient restClient;
  late int start;

  Future<void> _onCashBookSearchChanged(
    CashBookSearchChanged event,
    Emitter<CashBookState> emit,
  ) async {
    return _onCashBookFetch(
      CashBookFetch(
        refresh: true,
        searchString: event.searchString,
        isIncome: event.isIncome,
      ),
      emit,
    );
  }

  Future<void> _onCashBookFetch(
    CashBookFetch event,
    Emitter<CashBookState> emit,
  ) async {
    if (state.status == CashBookStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.entries.length;
    }
    try {
      CashBookEntries result = await restClient.getCashBookEntry(
        start: start,
        limit: _cashBookLimit,
        searchString: event.searchString,
        isIncome: event.isIncome,
      );
      return emit(
        state.copyWith(
          status: CashBookStatus.success,
          entries: start == 0
              ? result.cashBookEntries
              : (List.of(state.entries)..addAll(result.cashBookEntries)),
          hasReachedMax: result.cashBookEntries.length < _cashBookLimit,
          searchString: event.searchString,
          isIncome: event.isIncome,
          clearIsIncome: event.isIncome == null,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCashBookUpdate(
    CashBookUpdate event,
    Emitter<CashBookState> emit,
  ) async {
    try {
      List<CashBookEntry> entries = List.from(state.entries);
      if (event.entry.transactionId != null) {
        CashBookEntry result = await restClient.updateCashBookEntry(
          cashBookEntry: event.entry,
        );
        int index = entries.indexWhere(
          (element) => element.transactionId == event.entry.transactionId,
        );
        if (index != -1) entries[index] = result;
        return emit(
          state.copyWith(
            status: CashBookStatus.success,
            entries: entries,
            message: 'cashBookUpdateSuccess',
          ),
        );
      } else {
        CashBookEntry result = await restClient.createCashBookEntry(
          cashBookEntry: event.entry,
        );
        entries.insert(0, result);
        return emit(
          state.copyWith(
            status: CashBookStatus.success,
            entries: entries,
            message: 'cashBookAddSuccess',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCashBookDelete(
    CashBookDelete event,
    Emitter<CashBookState> emit,
  ) async {
    try {
      await restClient.deleteCashBookEntry(
        transactionId: event.entry.transactionId!,
      );
      List<CashBookEntry> entries = List.from(state.entries)
        ..removeWhere(
          (element) => element.transactionId == event.entry.transactionId,
        );
      return emit(
        state.copyWith(
          status: CashBookStatus.success,
          entries: entries,
          message: 'cashBookDeleteSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCashBookCategoriesFetch(
    CashBookCategoriesFetch event,
    Emitter<CashBookState> emit,
  ) async {
    if (state.incomeCategories.isNotEmpty && !event.refresh) return;
    try {
      GlAccounts income = await restClient.getCashBookCategory(isIncome: true);
      GlAccounts expenses = await restClient.getCashBookCategory(
        isIncome: false,
      );
      return emit(
        state.copyWith(
          status: CashBookStatus.categoriesSuccess,
          incomeCategories: income.glAccounts,
          expenseCategories: expenses.glAccounts,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
