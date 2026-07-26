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

abstract class SubscriptionEvent {
  const SubscriptionEvent();
  List<Object> get props => [];
}

class SubscriptionFetch extends SubscriptionEvent {
  const SubscriptionFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit,
    this.growerp = false,
  });
  final String searchString; // Search string to filter subscriptions
  final bool growerp; // Set to true if this is a GrowERP subscription
  final bool refresh; // Whether to refresh the data
  final int? limit; // Optional limit for the number of subscriptions to fetch
  @override
  List<Object> get props => [searchString, refresh, growerp];
}

class SubscriptionUpdate extends SubscriptionEvent {
  final Subscription subscription;
  const SubscriptionUpdate(this.subscription);
}

class SubscriptionDelete extends SubscriptionEvent {
  final Subscription subscription;
  const SubscriptionDelete(this.subscription);
}

class SubscriptionSearchChanged extends SubscriptionEvent {
  const SubscriptionSearchChanged({
    required this.searchString,
    this.growerp = false,
    this.limit = 20,
  });
  final String searchString;
  final bool growerp;
  final int limit;
  @override
  List<Object> get props => [searchString, growerp];
}
