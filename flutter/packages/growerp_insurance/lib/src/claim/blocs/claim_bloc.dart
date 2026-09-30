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
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'claim_event.dart';
part 'claim_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<ClaimSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

/// Claims of the agency; the backend limits a client to the claims on its
/// own policies.
class ClaimBloc extends Bloc<ClaimEvent, ClaimState> {
  final RestClient restClient;

  ClaimBloc(this.restClient) : super(const ClaimState()) {
    on<ClaimsFetch>(
      _onClaimsFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<ClaimSearchChanged>(
      _onClaimSearchChanged,
      transformer: _searchDebounce(),
    );
    on<ClaimUpdate>(_onClaimUpdate);
    on<ClaimDelete>(_onClaimDelete);
  }

  Future<void> _onClaimsFetch(
    ClaimsFetch event,
    Emitter<ClaimState> emit,
  ) async {
    final newQuery = event.refresh || event.searchString != state.searchString;
    if (state.hasReachedMax && !newQuery) return;
    try {
      emit(state.copyWith(status: ClaimStatusBloc.loading));
      final result = await restClient.getClaims(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: newQuery ? 0 : state.claims.length,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: ClaimStatusBloc.success,
          claims: newQuery
              ? result.claims
              : [...state.claims, ...result.claims],
          hasReachedMax: result.claims.length < event.limit,
          searchString: event.searchString,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClaimStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onClaimSearchChanged(
    ClaimSearchChanged event,
    Emitter<ClaimState> emit,
  ) async {
    return _onClaimsFetch(
      ClaimsFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }

  Future<void> _onClaimUpdate(
    ClaimUpdate event,
    Emitter<ClaimState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ClaimStatusBloc.loading));
      final updated = event.claim.claimId.isEmpty
          ? await restClient.createClaim(claim: event.claim)
          : await restClient.updateClaim(claim: event.claim);
      final list = List<Claim>.from(state.claims);
      final index = list.indexWhere((c) => c.claimId == updated.claimId);
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(state.copyWith(status: ClaimStatusBloc.success, claims: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: ClaimStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onClaimDelete(
    ClaimDelete event,
    Emitter<ClaimState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ClaimStatusBloc.loading));
      await restClient.deleteClaim(claim: event.claim);
      emit(
        state.copyWith(
          status: ClaimStatusBloc.success,
          claims: List<Claim>.from(state.claims)
            ..removeWhere((c) => c.claimId == event.claim.claimId),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClaimStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
