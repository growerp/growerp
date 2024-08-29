/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the websiteor(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
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
    on<ContentFetch>(_onContentFetch,
        transformer:
            websiteContentDroppable(const Duration(milliseconds: 100)));
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
        return emit(state.copyWith(
            status: ContentStatus.success, content: event.content));
      }
      final result = await restClient.getWebsiteContent(
          path: event.content.path, text: event.content.text);
      emit(state.copyWith(
        status: ContentStatus.success,
        content: result,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ContentStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onContentUpdate(
    ContentUpdate event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentStatus.updating));
      final Content result =
          await restClient.uploadWebsiteContent(content: event.content);
      emit(state.copyWith(
          content: result,
          status: ContentStatus.success,
          message: 'Content ${event.content.title} updated'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ContentStatus.failure, message: await getDioError(e)));
    }
  }
}
