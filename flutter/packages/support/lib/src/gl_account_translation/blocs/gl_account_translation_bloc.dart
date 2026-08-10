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
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'gl_account_translation_event.dart';
part 'gl_account_translation_state.dart';

EventTransformer<E> glAccountTranslationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// GL account name translations, one row per language. The translation runs in
/// the background on the server and commits every batch, so while a run is busy
/// this bloc polls: the counts creep up until the language is complete.
class GlAccountTranslationBloc
    extends Bloc<GlAccountTranslationEvent, GlAccountTranslationState> {
  GlAccountTranslationBloc(this.restClient)
    : super(const GlAccountTranslationState()) {
    on<GlAccountTranslationFetch>(
      _onFetch,
      transformer: glAccountTranslationDroppable(
        const Duration(milliseconds: 100),
      ),
    );
    on<GlAccountTranslationCreate>(_onCreate);
    on<GlAccountTranslationDelete>(_onDelete);
  }

  final RestClient restClient;
  static const int _pollSeconds = 5;
  Timer? _pollTimer;

  /// the languages a run was started for, the ones to poll for
  final Set<String> _running = {};

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  /// Poll only while a run this session started is still incomplete, so an idle
  /// page is quiet.
  void _schedulePoll(List<GlAccountTranslation> translations) {
    _pollTimer?.cancel();
    if (_running.isEmpty || isClosed) return;
    for (final translation in translations) {
      if (_running.contains(translation.locale) && translation.isCompleted) {
        _running.remove(translation.locale);
      }
    }
    if (_running.isEmpty) return;
    _pollTimer = Timer(const Duration(seconds: _pollSeconds), () {
      if (!isClosed) {
        add(const GlAccountTranslationFetch(refresh: true, background: true));
      }
    });
  }

  Future<void> _onFetch(
    GlAccountTranslationFetch event,
    Emitter<GlAccountTranslationState> emit,
  ) async {
    if (state.status == GlAccountTranslationStatus.initial &&
        !event.background) {
      emit(state.copyWith(status: GlAccountTranslationStatus.loading));
    }
    try {
      final result = await restClient.getGlAccountTranslation(
        start: 0,
        limit: event.limit,
        search: event.searchString.isEmpty ? null : event.searchString,
      );
      emit(
        state.copyWith(
          // a background poll must not look like a user action: an open dialog
          // closes itself on a plain success
          status: event.background
              ? GlAccountTranslationStatus.pollSuccess
              : GlAccountTranslationStatus.success,
          translations: result.glAccountTranslations,
          searchString: event.searchString,
        ),
      );
      _schedulePoll(result.glAccountTranslations);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  Future<void> _onCreate(
    GlAccountTranslationCreate event,
    Emitter<GlAccountTranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountTranslationStatus.loading));
      await restClient.createGlAccountTranslation(
        sourceLocale: event.sourceLocale,
        targetLocale: event.targetLocale,
      );
      _running.add(event.targetLocale);
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.success,
          message:
              'Translation started in the background, '
              'the counts update while it runs...',
        ),
      );
      add(const GlAccountTranslationFetch(refresh: true, background: true));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  Future<void> _onDelete(
    GlAccountTranslationDelete event,
    Emitter<GlAccountTranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountTranslationStatus.loading));
      await restClient.deleteGlAccountTranslation(
        locale: event.translation.locale,
      );
      _running.remove(event.translation.locale);
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.success,
          message: '${event.translation.language} translations removed',
        ),
      );
      add(const GlAccountTranslationFetch(refresh: true, background: true));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GlAccountTranslationStatus.failure,
          message: '$e',
        ),
      );
    }
  }
}
