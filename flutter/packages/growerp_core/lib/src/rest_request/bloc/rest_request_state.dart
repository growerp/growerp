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

part of 'rest_request_bloc.dart';

enum RestRequestStatus { initial, loading, success, failure }

class RestRequestState extends Equatable {
  const RestRequestState({
    this.status = RestRequestStatus.initial,
    this.restRequests = const <RestRequest>[],
    this.hasReachedMax = false,
    this.searchString = '',
    this.message,
  });

  final RestRequestStatus status;
  final List<RestRequest> restRequests;
  final bool hasReachedMax;
  final String searchString;
  final String? message;

  RestRequestState copyWith({
    RestRequestStatus? status,
    List<RestRequest>? restRequests,
    bool? hasReachedMax,
    String? searchString,
    String? message,
  }) {
    return RestRequestState(
      status: status ?? this.status,
      restRequests: restRequests ?? this.restRequests,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return '''RestRequestState { status: $status, hasReachedMax: $hasReachedMax, restRequests: ${restRequests.length} }''';
  }

  @override
  List<Object?> get props => [
    status,
    restRequests,
    hasReachedMax,
    searchString,
    message,
  ];
}
