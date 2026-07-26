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
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';

part 'content_event.dart';
part 'content_state.dart';

EventTransformer<E> websiteContentDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  ContentBloc(this.restClient) : super(const ContentState()) {
    on<ContentFetch>(
      _onContentFetch,
      transformer: websiteContentDroppable(const Duration(milliseconds: 100)),
    );
    on<ContentUpdate>(_onContentUpdate);
  }

  final RestClient restClient;

  Future<void> _onContentFetch(
    ContentFetch event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentStatus.loading));
      if (event.content.path.isEmpty) {
        return emit(
          state.copyWith(status: ContentStatus.success, content: event.content),
        );
      }
      final result = await restClient.getWebsiteContent(
        path: event.content.path,
        text: event.content.text,
      );
      emit(state.copyWith(status: ContentStatus.success, content: result));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onContentUpdate(
    ContentUpdate event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentStatus.updating));
      final Content result = await restClient.uploadWebsiteContent(
        content: event.content,
      );
      emit(
        state.copyWith(
          content: result,
          status: ContentStatus.success,
          message: 'contentUpdateSuccess:${event.content.title}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
