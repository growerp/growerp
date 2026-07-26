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

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';

import 'models.dart';

part 'gateway_response_model.freezed.dart';
part 'gateway_response_model.g.dart';

@freezed
abstract class GatewayResponse extends Equatable with _$GatewayResponse {
  const GatewayResponse._();
  const factory GatewayResponse({
    @Default("") String gatewayResponseId,
    @Default("") String paymentOperation,
    PaymentMethod? paymentMethod,
    @Default("") String paymentId,
    @Default("") String pseudoId,
    Decimal? amount,
    @DateTimeConverter() DateTime? transactionDate,
    @Default(false) bool resultSuccess,
    String? resultMessage,
    String? referenceNum,
  }) = _GatewayResponse;

  factory GatewayResponse.fromJson(Map<String, dynamic> json) =>
      _$GatewayResponseFromJson(json['gatewayResponse'] ?? json);

  @override
  List<Object?> get props => [gatewayResponseId];

  @override
  String toString() =>
      'GatewayResponse $gatewayResponseId $paymentOperation #$paymentId/$pseudoId $resultSuccess';
}
