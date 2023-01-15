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
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';
import '../../api_repository.dart';
import '../website.dart';

part 'content_event.dart';
part 'content_state.dart';

EventTransformer<E> websiteContentDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  ContentBloc(this.repos) : super(const ContentState()) {
    on<ContentInit>((event, emit) => emit(
        state.copyWith(content: Content(), status: ContentStatus.success)));
    on<ContentFetch>(_onContentFetch,
        transformer:
            websiteContentDroppable(const Duration(milliseconds: 100)));
    on<ContentUpdate>(_onContentUpdate);
  }

  final WebsiteAPIRepository repos;

  Future<void> _onContentFetch(
    ContentFetch event,
    Emitter<ContentState> emit,
  ) async {
    emit(state.copyWith(status: ContentStatus.loading));
    ApiResult result = await repos.getWebsiteContent(event.content);
    return emit(result.when(
        success: (data) {
          return state.copyWith(
            status: ContentStatus.success,
            content: data,
          );
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ContentStatus.failure, message: error.toString())));
  }

  Future<void> _onContentUpdate(
    ContentUpdate event,
    Emitter<ContentState> emit,
  ) async {
    emit(state.copyWith(status: ContentStatus.loading));
    ApiResult result =
        await repos.uploadWebsiteContent(event.websiteId, event.content);
    return emit(result.when(
        success: (data) {
          return state.copyWith(
              content: data,
              status: ContentStatus.success,
              message: 'Content Content updated');
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ContentStatus.failure, message: error.toString())));
  }
}
