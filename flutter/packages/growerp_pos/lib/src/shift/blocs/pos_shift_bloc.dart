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

part 'pos_shift_event.dart';
part 'pos_shift_state.dart';

/// The shift of this till, and the shifts of the company for the admin.
class PosShiftBloc extends Bloc<PosShiftEvent, PosShiftState> {
  final RestClient restClient;

  PosShiftBloc(this.restClient) : super(const PosShiftState()) {
    on<PosShiftFetch>(_onFetch, transformer: restartable());
    on<PosShiftOpen>(_onOpen, transformer: droppable());
    on<PosCashMovementAdd>(_onMovement, transformer: droppable());
    on<PosShiftClose>(_onClose, transformer: droppable());
    on<PosShiftListFetch>(_onList, transformer: droppable());
    on<PosZReportFetch>(_onReport, transformer: restartable());
  }

  Future<void> _failed(DioException e, Emitter<PosShiftState> emit) async {
    emit(
      state.copyWith(
        // a company of another app, or the screen taken away from this group
        status: e.response?.statusCode == 403
            ? PosShiftStatus.noAccess
            : PosShiftStatus.failure,
        message: await getDioError(e),
      ),
    );
  }

  Future<void> _onFetch(
    PosShiftFetch event,
    Emitter<PosShiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PosShiftStatus.loading));
      final shift = await restClient.getPosShift(
        terminalName: event.terminalName,
      );
      emit(
        PosShiftState(
          status: PosShiftStatus.success,
          shift: shift.shiftId == null ? null : shift,
          shifts: state.shifts,
        ),
      );
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  Future<void> _onOpen(PosShiftOpen event, Emitter<PosShiftState> emit) async {
    try {
      emit(state.copyWith(status: PosShiftStatus.loading));
      final shift = await restClient.openPosShift(
        terminalName: event.terminalName,
        openingFloat: event.openingFloat,
      );
      emit(state.copyWith(status: PosShiftStatus.success, shift: shift));
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  Future<void> _onMovement(
    PosCashMovementAdd event,
    Emitter<PosShiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PosShiftStatus.loading));
      await restClient.createPosCashMovement(
        shiftId: state.shift!.shiftId!,
        amount: event.amount,
        reason: event.reason,
      );
      emit(state.copyWith(status: PosShiftStatus.success));
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  Future<void> _onClose(
    PosShiftClose event,
    Emitter<PosShiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PosShiftStatus.loading));
      final report = await restClient.closePosShift(
        shiftId: state.shift!.shiftId!,
        countedCash: event.countedCash,
      );
      emit(
        PosShiftState(
          status: PosShiftStatus.success,
          report: report,
          shifts: state.shifts,
        ),
      );
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  Future<void> _onList(
    PosShiftListFetch event,
    Emitter<PosShiftState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;
    try {
      final start = event.refresh ? 0 : state.shifts.length;
      emit(
        state.copyWith(
          status: PosShiftStatus.loading,
          shifts: event.refresh ? const [] : null,
        ),
      );
      final result = await restClient.getPosShifts(
        start: start,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: PosShiftStatus.success,
          shifts: [...state.shifts, ...result.shifts],
          hasReachedMax: result.shifts.length < event.limit,
        ),
      );
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  Future<void> _onReport(
    PosZReportFetch event,
    Emitter<PosShiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PosShiftStatus.loading));
      final report = await restClient.getPosZReport(shiftId: event.shiftId);
      emit(state.copyWith(status: PosShiftStatus.reported, report: report));
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }
}
