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
