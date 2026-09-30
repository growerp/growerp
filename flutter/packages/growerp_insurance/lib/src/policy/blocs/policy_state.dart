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

part of 'policy_bloc.dart';

/// Named ...Bloc: PolicyStatus is the status of the policy itself.
enum PolicyStatusBloc { initial, loading, success, failure }

class PolicyState extends Equatable {
  const PolicyState({
    this.status = PolicyStatusBloc.initial,
    this.policies = const <Policy>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.expiringWithinDays = 0,
  });

  final PolicyStatusBloc status;
  final String? message;
  final List<Policy> policies;
  final bool hasReachedMax;
  final String searchString;
  final int expiringWithinDays; // 0: all policies

  PolicyState copyWith({
    PolicyStatusBloc? status,
    String? message,
    List<Policy>? policies,
    bool? hasReachedMax,
    String? searchString,
    int? expiringWithinDays,
  }) {
    return PolicyState(
      status: status ?? this.status,
      policies: policies ?? this.policies,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      expiringWithinDays: expiringWithinDays ?? this.expiringWithinDays,
    );
  }

  @override
  List<Object?> get props => [policies, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #policies: ${policies.length}, message: $message }';
}
