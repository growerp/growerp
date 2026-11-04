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

part 'pos_catalog_event.dart';
part 'pos_catalog_state.dart';

/// What the till sells. Fetched once, searching filters it in the screen.
class PosCatalogBloc extends Bloc<PosCatalogEvent, PosCatalogState> {
  final RestClient restClient;

  PosCatalogBloc(this.restClient) : super(const PosCatalogState()) {
    on<PosCatalogFetch>(_onFetch, transformer: droppable());
    on<PosBarcodeScan>(_onScan);
  }

  Future<void> _onFetch(
    PosCatalogFetch event,
    Emitter<PosCatalogState> emit,
  ) async {
    if (state.status != PosCatalogStatus.initial && !event.refresh) return;
    try {
      emit(state.copyWith(status: PosCatalogStatus.loading));
      final catalog = await restClient.getPosCatalog();
      emit(
        state.copyWith(
          status: PosCatalogStatus.success,
          items: catalog.items,
          pricesIncludeTax: catalog.pricesIncludeTax,
          currencyId: catalog.currencyId,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosCatalogStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onScan(
    PosBarcodeScan event,
    Emitter<PosCatalogState> emit,
  ) async {
    try {
      final item = await restClient.getPosProductByBarcode(
        barcode: event.barcode,
      );
      emit(state.copyWith(status: PosCatalogStatus.scanned, scanned: item));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosCatalogStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
