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

import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'pos_sale_event.dart';
part 'pos_sale_state.dart';

/// Sends the sale. The id is made once per checkout and kept until the sale is
/// done: after a lost connection the same id gets the first sale back instead
/// of selling twice.
class PosSaleBloc extends Bloc<PosSaleEvent, PosSaleState> {
  final RestClient restClient;

  PosSaleBloc(this.restClient) : super(const PosSaleState()) {
    on<PosSaleSubmit>(_onSubmit, transformer: droppable());
    on<PosSaleReset>((event, emit) => emit(const PosSaleState()));
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  Future<void> _onSubmit(
    PosSaleSubmit event,
    Emitter<PosSaleState> emit,
  ) async {
    final clientSaleId = state.clientSaleId ?? _newId();
    emit(
      state.copyWith(status: PosSaleStatus.loading, clientSaleId: clientSaleId),
    );
    try {
      final sale = await restClient.createPosSale(
        clientSaleId: clientSaleId,
        terminalName: event.terminalName,
        lines: event.lines,
        tenders: event.tenders,
      );
      emit(state.copyWith(status: PosSaleStatus.success, sale: sale));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosSaleStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
