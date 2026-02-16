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

part of 'subscription_bloc.dart';

enum SubscriptionStatus { initial, success, failure, loading }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.subscriptions = const <Subscription>[],
    this.hasReachedMax = false,
    this.message,
    this.searchString = '',
  });

  final SubscriptionStatus status;
  final List<Subscription> subscriptions;
  final bool hasReachedMax;
  final String? message;
  final String searchString;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<Subscription>? subscriptions,
    bool? hasReachedMax,
    String? message,
    String? searchString,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscriptions: subscriptions ?? this.subscriptions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      message: message ?? this.message,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, subscriptions, hasReachedMax];

  @override
  String toString() =>
      '$status { #subscriptions: ${subscriptions.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
