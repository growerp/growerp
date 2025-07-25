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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Represents a subscription in the GrowERP system.
@freezed
class Subscription with _$Subscription {
  Subscription._();
  factory Subscription({
    String? subscriptionId, // Unique systemwide identifier for the subscription
    String?
        pseudoId, // Unique identifier for the subscription, used for this owner
    String? subscriberPartyId, // Party that is subscribing
    String? orderId, // Order that created this subscription
    String? orderItemSeqId, // Order item that created this subscription
    String? productId, // Product/plan associated with this subscription
    String? description, //
    @DateTimeConverter() DateTime? fromDate, // Start date of the subscription
    @DateTimeConverter() DateTime? thruDate, // End date of the subscription
    @DateTimeConverter() DateTime? purchaseFromDate, // Purchase start date
    @DateTimeConverter() DateTime? purchaseThruDate, // Purchase end date
    Decimal? availableTime, // Total time available for this subscription
    String? availableTimeUomId, // UOM for available time
    Decimal? useTime, // Time used from the subscription
    String? useTimeUomId, // UOM for used time
  }) = _Subscription;

  /// Converts a JSON map to a Subscription object.
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json['subscription'] ?? json);
}
