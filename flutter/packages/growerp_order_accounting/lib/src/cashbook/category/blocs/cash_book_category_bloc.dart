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

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'cash_book_category_event.dart';
part 'cash_book_category_state.dart';

/// The income and expense categories of the cash book: the ledger accounts of
/// the company, with the ones the company actually uses switched on. The list
/// is short enough to fetch in one go, so searching filters it here.
class CashBookCategoryBloc
    extends Bloc<CashBookCategoryEvent, CashBookCategoryState> {
  final RestClient restClient;

  CashBookCategoryBloc(this.restClient) : super(const CashBookCategoryState()) {
    on<CashBookCategoryFetch>(_onFetch, transformer: restartable());
    on<CashBookCategoryUpdate>(_onUpdate);
    on<CashBookCategoryCreate>(_onCreate);
  }

  Future<void> _onFetch(
    CashBookCategoryFetch event,
    Emitter<CashBookCategoryState> emit,
  ) async {
    if (state.status != CashBookCategoryStatus.initial && !event.refresh) {
      return;
    }
    try {
      emit(state.copyWith(status: CashBookCategoryStatus.loading));
      final income = await restClient.getCashBookCategory(isIncome: true);
      final expenses = await restClient.getCashBookCategory(isIncome: false);
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.success,
          incomeCategories: income.glAccounts,
          expenseCategories: expenses.glAccounts,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    CashBookCategoryUpdate event,
    Emitter<CashBookCategoryState> emit,
  ) async {
    try {
      final updated = await restClient.updateCashBookCategory(
        glAccountId: event.category.glAccountId!,
        isUsed: event.isUsed,
        accountName: event.accountName,
      );
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.success,
          message: 'cashBookCategoryUpdateSuccess',
          incomeCategories: _replace(state.incomeCategories, updated),
          expenseCategories: _replace(state.expenseCategories, updated),
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCreate(
    CashBookCategoryCreate event,
    Emitter<CashBookCategoryState> emit,
  ) async {
    try {
      final created = await restClient.createCashBookCategory(
        accountName: event.accountName,
        isIncome: event.isIncome,
      );
      final list = List<GlAccount>.from(
        event.isIncome ? state.incomeCategories : state.expenseCategories,
      )..insert(0, created);
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.success,
          message: 'cashBookCategoryAddSuccess',
          incomeCategories: event.isIncome ? list : null,
          expenseCategories: event.isIncome ? null : list,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CashBookCategoryStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  List<GlAccount> _replace(List<GlAccount> list, GlAccount updated) {
    final index = list.indexWhere((c) => c.glAccountId == updated.glAccountId);
    if (index < 0) return list;
    return List<GlAccount>.from(list)..[index] = updated;
  }
}
