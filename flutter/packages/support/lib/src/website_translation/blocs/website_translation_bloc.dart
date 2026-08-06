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

part 'website_translation_event.dart';
part 'website_translation_state.dart';

EventTransformer<E> websiteTranslationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Website translations. A translation runs in the background on the server, so
/// while any row is still working this bloc polls for progress.
class WebsiteTranslationBloc
    extends Bloc<WebsiteTranslationEvent, WebsiteTranslationState> {
  WebsiteTranslationBloc(this.restClient)
    : super(const WebsiteTranslationState()) {
    on<WebsiteTranslationFetch>(
      _onFetch,
      transformer: websiteTranslationDroppable(
        const Duration(milliseconds: 100),
      ),
    );
    on<WebsiteTranslationCreate>(_onCreate);
    on<WebsiteTranslationDelete>(_onDelete);
  }

  final RestClient restClient;
  static const int _pollSeconds = 5;
  Timer? _pollTimer;

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  /// Keep polling only while something is actually running, so an idle page is quiet.
  void _schedulePoll(List<WebsiteTranslation> translations) {
    _pollTimer?.cancel();
    if (translations.any((t) => t.inProgress) && !isClosed) {
      _pollTimer = Timer(const Duration(seconds: _pollSeconds), () {
        if (!isClosed) {
          add(const WebsiteTranslationFetch(refresh: true, background: true));
        }
      });
    }
  }

  Future<void> _onFetch(
    WebsiteTranslationFetch event,
    Emitter<WebsiteTranslationState> emit,
  ) async {
    if (state.status == WebsiteTranslationStatus.initial && !event.background) {
      emit(state.copyWith(status: WebsiteTranslationStatus.loading));
    }
    try {
      final result = await restClient.getWebsiteTranslation(
        start: 0,
        limit: event.limit,
        search: event.searchString.isEmpty ? null : event.searchString,
      );
      // tell the user when a translation finished while they were doing
      // something else
      String? finishedMessage;
      if (event.background) {
        for (final fresh in result.websiteTranslations) {
          final was = state.translations.where(
            (t) => t.translationId == fresh.translationId,
          );
          if (was.isNotEmpty && was.first.inProgress && !fresh.inProgress) {
            finishedMessage = fresh.isCompleted
                ? 'Website of ${fresh.ownerName} translated'
                : 'Translation of ${fresh.ownerName} failed';
          }
        }
      }

      // an open dialog reads `selected`, so it has to follow the poll too, or it
      // shows the status the translation had when the dialog was opened forever
      WebsiteTranslation? selected = state.selected;
      if (selected != null) {
        final matches = result.websiteTranslations.where(
          (t) => t.translationId == selected!.translationId,
        );
        if (matches.isNotEmpty) selected = matches.first;
      }
      emit(
        state.copyWith(
          // a background poll must not look like a user action: an open dialog
          // closes itself on a plain success
          status: event.background
              ? WebsiteTranslationStatus.pollSuccess
              : WebsiteTranslationStatus.success,
          translations: result.websiteTranslations,
          selected: selected,
          message: finishedMessage,
          searchString: event.searchString,
        ),
      );
      _schedulePoll(result.websiteTranslations);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(status: WebsiteTranslationStatus.failure, message: '$e'),
      );
    }
  }

  Future<void> _onCreate(
    WebsiteTranslationCreate event,
    Emitter<WebsiteTranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteTranslationStatus.loading));
      final created = await restClient.createWebsiteTranslation(
        ownerPartyId: event.ownerPartyId,
        sourceLocale: event.sourceLocale,
        targetLocales: event.targetLocales,
        translateEntityNames: event.translateEntityNames ? 'Y' : 'N',
        overwriteExisting: event.overwriteExisting ? 'Y' : 'N',
      );
      final translations = List<WebsiteTranslation>.from(state.translations)
        ..insert(0, created);
      emit(
        state.copyWith(
          status: WebsiteTranslationStatus.success,
          translations: translations,
          message:
              'Translation started in the background, '
              'the list updates while it runs...',
        ),
      );
      _schedulePoll(translations);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: WebsiteTranslationStatus.failure, message: '$e'),
      );
    }
  }

  Future<void> _onDelete(
    WebsiteTranslationDelete event,
    Emitter<WebsiteTranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteTranslationStatus.loading));
      await restClient.deleteWebsiteTranslation(
        translationId: event.translation.translationId,
      );
      emit(
        state.copyWith(
          status: WebsiteTranslationStatus.success,
          translations: List<WebsiteTranslation>.from(state.translations)
            ..removeWhere(
              (t) => t.translationId == event.translation.translationId,
            ),
          message: 'Translation removed from the list',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteTranslationStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: WebsiteTranslationStatus.failure, message: '$e'),
      );
    }
  }
}
