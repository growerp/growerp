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

part of 'routing_bloc.dart';

enum RoutingStatus { initial, loading, success, failure }

class RoutingState extends Equatable {
  const RoutingState({
    this.status = RoutingStatus.initial,
    this.routings = const <Routing>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final RoutingStatus status;
  final String? message;
  final List<Routing> routings;
  final bool hasReachedMax;
  final String searchString;

  RoutingState copyWith({
    RoutingStatus? status,
    String? message,
    List<Routing>? routings,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return RoutingState(
      status: status ?? this.status,
      routings: routings ?? this.routings,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [routings, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #routings: ${routings.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
