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
