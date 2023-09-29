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

import 'package:json_annotation/json_annotation.dart';
import 'models.dart';

part 'payment_method_model.g.dart';

@JsonSerializable()
class PaymentMethod {
  String? ccPaymentMethodId;
  String? ccDescription;
  String? creditCardNumber;
  @CreditCardTypeConverter()
  CreditCardType? creditCardType;
  String? expireMonth;
  String? expireYear;

  PaymentMethod({
    this.ccPaymentMethodId,
    this.ccDescription,
    this.creditCardNumber,
    this.creditCardType,
    this.expireMonth,
    this.expireYear,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
