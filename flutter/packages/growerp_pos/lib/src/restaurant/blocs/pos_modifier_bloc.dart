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

part 'pos_modifier_event.dart';
part 'pos_modifier_state.dart';

/// The modifier groups of the company. Few enough to fetch in one go.
class PosModifierBloc extends Bloc<PosModifierEvent, PosModifierState> {
  final RestClient restClient;

  PosModifierBloc(this.restClient) : super(const PosModifierState()) {
    on<PosModifierEvent>(_onEvent, transformer: sequential());
  }

  Future<void> _onEvent(
    PosModifierEvent event,
    Emitter<PosModifierState> emit,
  ) async {
    try {
      String? message;
      if (event is PosModifierSave) {
        await restClient.storePosModifierGroup(group: event.group);
        message = 'saved';
      }
      if (event is PosModifierDelete) {
        await restClient.deletePosModifierGroup(groupId: event.groupId);
        message = 'saved';
      }
      final result = await restClient.getPosModifierGroups();
      emit(
        state.copyWith(
          status: PosModifierStatus.success,
          groups: result.modifierGroups,
          message: message,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosModifierStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
