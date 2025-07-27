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

abstract class SubscriptionEvent {
  const SubscriptionEvent();
  List<Object> get props => [];
}

class SubscriptionFetch extends SubscriptionEvent {
  const SubscriptionFetch(
      {this.searchString = '',
      this.refresh = false,
      this.limit,
      this.growerp = false});
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
