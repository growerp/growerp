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

import '../json_converters.dart';
import 'models.dart';

part 'payment_method_model.freezed.dart';
part 'payment_method_model.g.dart';

@freezed
abstract class PaymentMethod with _$PaymentMethod {
  PaymentMethod._();
  factory PaymentMethod({
    String? ccPaymentMethodId,
    String? ccDescription,
    String? ccNameOnCard,
    String? creditCardNumber,
    String? checkNumber,
    @CreditCardTypeConverter() CreditCardType? creditCardType,
    String? expireMonth,
    String? expireYear,
    String? cVC,
  }) = _PaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json['paymentMethod'] ?? json);
}
