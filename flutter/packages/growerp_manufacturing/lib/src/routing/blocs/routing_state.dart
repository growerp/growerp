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
