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
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'pos_cart_event.dart';
part 'pos_cart_state.dart';

/// The lines of the sale at the till. Totals and tax always come from the
/// backend. One event at a time, so a late answer cannot overwrite a newer one.
class PosCartBloc extends Bloc<PosCartEvent, PosCartState> {
  final RestClient restClient;

  PosCartBloc(this.restClient) : super(const PosCartState()) {
    on<PosCartEvent>(_onEvent, transformer: sequential());
  }

  Future<void> _onEvent(PosCartEvent event, Emitter<PosCartState> emit) async {
    final lines = switch (event) {
      PosCartAdd() => _added(event.item),
      PosCartQuantity() => _changed(event.productId, event.quantity),
      _ => <PosCartLine>[],
    };
    if (lines.isEmpty) {
      emit(const PosCartState(status: PosCartStatus.success));
      return;
    }
    emit(state.copyWith(status: PosCartStatus.loading, lines: lines));
    try {
      final quote = await restClient.getPosQuote(
        lines: lines
            .map(
              (line) => PosLine(
                productId: line.item.productId,
                quantity: line.quantity,
              ),
            )
            .toList(),
      );
      emit(
        state.copyWith(
          status: PosCartStatus.success,
          taxTotal: quote.taxTotal,
          grandTotal: quote.grandTotal,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosCartStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  List<PosCartLine> _added(PosCatalogItem item) {
    final index = state.lines.indexWhere(
      (line) => line.item.productId == item.productId,
    );
    if (index < 0) {
      return [...state.lines, PosCartLine(item, Decimal.one)];
    }
    final line = state.lines[index];
    return List<PosCartLine>.from(state.lines)
      ..[index] = PosCartLine(line.item, line.quantity + Decimal.one);
  }

  List<PosCartLine> _changed(String productId, Decimal quantity) {
    return state.lines
        .map(
          (line) => line.item.productId == productId
              ? PosCartLine(line.item, quantity)
              : line,
        )
        .where((line) => line.quantity > Decimal.zero)
        .toList();
  }
}
