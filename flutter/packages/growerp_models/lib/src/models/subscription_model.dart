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

@freezed
class Subscription with _$Subscription {
  Subscription._();
  factory Subscription({
    String? subscriptionId,
    String? subscriptionTypeEnumId,
    String? subscriptionResourceId,
    String? subscriberPartyId,
    String? deliverToContactMechId,
    String? orderId,
    String? orderItemSeqId,
    String? productId,
    String? externalSubscriptionId,
    String? resourceInstanceId,
    String? description,
    @DateTimeConverter() DateTime? fromDate,
    @DateTimeConverter() DateTime? thruDate,
    @DateTimeConverter() DateTime? purchaseFromDate,
    @DateTimeConverter() DateTime? purchaseThruDate,
    Decimal? availableTime,
    String? availableTimeUomId,
    Decimal? useTime,
    String? useTimeUomId,
    Decimal? useCountLimit,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json['subscription'] ?? json);
}
