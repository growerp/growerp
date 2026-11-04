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

part 'pos_refund_event.dart';
part 'pos_refund_state.dart';

/// Find a sale by its receipt and give money back. Like a sale, the id stays
/// the same over retries until the refund is done.
class PosRefundBloc extends Bloc<PosRefundEvent, PosRefundState> {
  final RestClient restClient;

  PosRefundBloc(this.restClient) : super(const PosRefundState()) {
    on<PosRefundLookup>(_onLookup, transformer: restartable());
    on<PosRefundSubmit>(_onSubmit, transformer: droppable());
    on<PosRefundReset>((event, emit) => emit(const PosRefundState()));
  }

  Future<void> _onLookup(
    PosRefundLookup event,
    Emitter<PosRefundState> emit,
  ) async {
    emit(const PosRefundState(status: PosRefundStatus.loading));
    try {
      final sale = await restClient.getPosSaleLookup(search: event.search);
      emit(state.copyWith(status: PosRefundStatus.found, sale: sale));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosRefundStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onSubmit(
    PosRefundSubmit event,
    Emitter<PosRefundState> emit,
  ) async {
    final id =
        state.clientRefundId ??
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    emit(state.copyWith(status: PosRefundStatus.loading, clientRefundId: id));
    try {
      final refund = await restClient.createPosRefund(
        clientRefundId: id,
        clientSaleId: state.sale!.clientSaleId!,
        lines: event.lines,
        restock: event.restock,
      );
      emit(state.copyWith(status: PosRefundStatus.success, refund: refund));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosRefundStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
