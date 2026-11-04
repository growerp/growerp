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

part 'tax_rate_event.dart';
part 'tax_rate_state.dart';

/// The sales tax rates of the company. Few enough to fetch in one go.
class TaxRateBloc extends Bloc<TaxRateEvent, TaxRateState> {
  final RestClient restClient;

  TaxRateBloc(this.restClient) : super(const TaxRateState()) {
    on<TaxRateFetch>(_onFetch, transformer: restartable());
    on<TaxRateUpdate>(_onUpdate);
    on<TaxRateDelete>(_onDelete);
    on<TaxSettingsUpdate>(_onSettings);
  }

  Future<void> _onFetch(TaxRateFetch event, Emitter<TaxRateState> emit) async {
    try {
      emit(state.copyWith(status: TaxRateStatus.loading));
      final result = await restClient.getTaxRates();
      emit(
        state.copyWith(
          status: TaxRateStatus.success,
          taxRates: result.taxRates,
          pricesIncludeTax: result.pricesIncludeTax,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: TaxRateStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    TaxRateUpdate event,
    Emitter<TaxRateState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaxRateStatus.loading));
      final isNew = event.taxRate.taxRateId == null;
      final saved = isNew
          ? await restClient.createTaxRate(taxRate: event.taxRate)
          : await restClient.updateTaxRate(taxRate: event.taxRate);
      final list = List<TaxRate>.from(state.taxRates);
      if (isNew) {
        list.insert(0, saved);
      } else {
        final index = list.indexWhere((r) => r.taxRateId == saved.taxRateId);
        if (index >= 0) list[index] = saved;
      }
      emit(
        state.copyWith(
          status: TaxRateStatus.success,
          taxRates: list,
          message: isNew ? 'taxRateAddSuccess' : 'taxRateUpdateSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: TaxRateStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onDelete(
    TaxRateDelete event,
    Emitter<TaxRateState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaxRateStatus.loading));
      await restClient.deleteTaxRate(taxRateId: event.taxRate.taxRateId!);
      emit(
        state.copyWith(
          status: TaxRateStatus.success,
          taxRates: state.taxRates
              .where((r) => r.taxRateId != event.taxRate.taxRateId)
              .toList(),
          message: 'taxRateDeleteSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: TaxRateStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onSettings(
    TaxSettingsUpdate event,
    Emitter<TaxRateState> emit,
  ) async {
    try {
      await restClient.updateTaxSettings(
        pricesIncludeTax: event.pricesIncludeTax,
      );
      emit(
        state.copyWith(
          status: TaxRateStatus.success,
          pricesIncludeTax: event.pricesIncludeTax,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: TaxRateStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
