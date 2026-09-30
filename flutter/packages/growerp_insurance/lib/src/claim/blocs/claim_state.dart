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

part of 'claim_bloc.dart';

/// Named ...Bloc: ClaimStatus is the status of the claim itself.
enum ClaimStatusBloc { initial, loading, success, failure }

class ClaimState extends Equatable {
  const ClaimState({
    this.status = ClaimStatusBloc.initial,
    this.claims = const <Claim>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final ClaimStatusBloc status;
  final String? message;
  final List<Claim> claims;
  final bool hasReachedMax;
  final String searchString;

  ClaimState copyWith({
    ClaimStatusBloc? status,
    String? message,
    List<Claim>? claims,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return ClaimState(
      status: status ?? this.status,
      claims: claims ?? this.claims,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [claims, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #claims: ${claims.length}, message: $message }';
}
