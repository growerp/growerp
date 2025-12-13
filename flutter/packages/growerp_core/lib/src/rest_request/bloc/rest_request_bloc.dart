/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
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
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../services/get_dio_error.dart';

part 'rest_request_event.dart';
part 'rest_request_state.dart';

EventTransformer<E> restRequestDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class RestRequestBloc extends Bloc<RestRequestEvent, RestRequestState> {
  RestRequestBloc(this.restClient) : super(const RestRequestState()) {
    on<RestRequestFetch>(
      _onRestRequestFetch,
      transformer: restRequestDroppable(const Duration(milliseconds: 100)),
    );
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onRestRequestFetch(
    RestRequestFetch event,
    Emitter<RestRequestState> emit,
  ) async {
    if (state.status == RestRequestStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.restRequests.length;
    }
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: RestRequestStatus.loading));

      RestRequests compResult = await restClient.getRestRequest(
        hitId: event.hitId,
        userId: event.userId,
        ownerPartyId: event.ownerPartyId,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        start: start,
        limit: event.limit,
      );

      return emit(
        state.copyWith(
          status: RestRequestStatus.success,
          restRequests: start == 0
              ? compResult.restRequests
              : (List.of(state.restRequests)..addAll(compResult.restRequests)),
          hasReachedMax: compResult.restRequests.length < event.limit
              ? true
              : false,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RestRequestStatus.failure,
          restRequests: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
