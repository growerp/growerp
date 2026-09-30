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
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'policy_event.dart';
part 'policy_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<PolicySearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class PolicyBloc extends Bloc<PolicyEvent, PolicyState> {
  final RestClient restClient;

  PolicyBloc(this.restClient) : super(const PolicyState()) {
    on<PoliciesFetch>(
      _onPoliciesFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<PolicySearchChanged>(
      _onPolicySearchChanged,
      transformer: _searchDebounce(),
    );
    on<PolicyUpdate>(_onPolicyUpdate);
    on<PolicyDelete>(_onPolicyDelete);
    on<PolicyRenew>(_onPolicyRenew);
    on<PolicyCommissionReceive>(_onPolicyCommissionReceive);
  }

  Future<void> _onPoliciesFetch(
    PoliciesFetch event,
    Emitter<PolicyState> emit,
  ) async {
    final newQuery =
        event.refresh ||
        event.searchString != state.searchString ||
        event.expiringWithinDays != state.expiringWithinDays;
    if (state.hasReachedMax && !newQuery) return;
    try {
      emit(state.copyWith(status: PolicyStatusBloc.loading));
      final result = await restClient.getPolicies(
        expiringWithinDays: event.expiringWithinDays > 0
            ? event.expiringWithinDays
            : null,
        search: event.searchString.isEmpty ? null : event.searchString,
        start: newQuery ? 0 : state.policies.length,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: PolicyStatusBloc.success,
          policies: newQuery
              ? result.policies
              : [...state.policies, ...result.policies],
          hasReachedMax: result.policies.length < event.limit,
          searchString: event.searchString,
          expiringWithinDays: event.expiringWithinDays,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PolicyStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onPolicySearchChanged(
    PolicySearchChanged event,
    Emitter<PolicyState> emit,
  ) async {
    return _onPoliciesFetch(
      PoliciesFetch(
        refresh: true,
        searchString: event.searchString,
        expiringWithinDays: state.expiringWithinDays,
      ),
      emit,
    );
  }

  List<Policy> _replace(Policy policy) {
    final list = List<Policy>.from(state.policies);
    final index = list.indexWhere((p) => p.policyId == policy.policyId);
    if (index >= 0) {
      list[index] = policy;
    } else {
      list.insert(0, policy);
    }
    return list;
  }

  Future<void> _onPolicyUpdate(
    PolicyUpdate event,
    Emitter<PolicyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PolicyStatusBloc.loading));
      final updated = event.policy.policyId.isEmpty
          ? await restClient.createPolicy(policy: event.policy)
          : await restClient.updatePolicy(policy: event.policy);
      emit(
        state.copyWith(
          status: PolicyStatusBloc.success,
          policies: _replace(updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PolicyStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onPolicyDelete(
    PolicyDelete event,
    Emitter<PolicyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PolicyStatusBloc.loading));
      await restClient.deletePolicy(policy: event.policy);
      emit(
        state.copyWith(
          status: PolicyStatusBloc.success,
          policies: List<Policy>.from(state.policies)
            ..removeWhere((p) => p.policyId == event.policy.policyId),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PolicyStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// The renewal is a new policy and the old one gets the status Renewed:
  /// the list is fetched again so both land where the current filter and
  /// order put them (a renewal list drops the renewed policy).
  Future<void> _onPolicyRenew(
    PolicyRenew event,
    Emitter<PolicyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PolicyStatusBloc.loading));
      await restClient.renewPolicy(policy: event.policy);
      final limit = state.policies.length < 20 ? 20 : state.policies.length;
      final result = await restClient.getPolicies(
        expiringWithinDays: state.expiringWithinDays > 0
            ? state.expiringWithinDays
            : null,
        search: state.searchString.isEmpty ? null : state.searchString,
        start: 0,
        limit: limit + 1,
      );
      emit(
        state.copyWith(
          status: PolicyStatusBloc.success,
          policies: result.policies,
          hasReachedMax: result.policies.length <= limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PolicyStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onPolicyCommissionReceive(
    PolicyCommissionReceive event,
    Emitter<PolicyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PolicyStatusBloc.loading));
      final updated = await restClient.receivePolicyCommission(
        policyId: event.policyId,
        amount: event.amount.toString(),
      );
      emit(
        state.copyWith(
          status: PolicyStatusBloc.success,
          policies: _replace(updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PolicyStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
