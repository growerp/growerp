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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Represents a subscription in the GrowERP system.
@freezed
abstract class Subscription with _$Subscription {
  Subscription._();
  factory Subscription({
    String? subscriptionId, // Unique systemwide identifier for the subscription
    String? pseudoId, // Unique owner identifier for the subscription
    CompanyUser? subscriber, // Party that is subscribing
    String? orderId, // Order that created this subscription
    String? orderItemSeqId, // Order item that created this subscription
    Product? product, // Product/plan associated with this subscription
    String? description, //
    DateTime? fromDate, // Start date of the subscription
    DateTime? thruDate, // End date of the subscription
    DateTime? purchaseFromDate, // Purchase start date
    DateTime? purchaseThruDate, // Purchase end date
    Duration? availableTime, // Total time available for this subscription
    Duration? useTime, // Time used or period time for renew
    Duration? trialPeriod, // Trial period duration
  }) = _Subscription;

  /// Converts a JSON map to a Subscription object.
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json['subscription'] ?? json);
}
