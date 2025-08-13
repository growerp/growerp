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
      'GatewayResponse $gatewayResponseId #$paymentId/$pseudoId $resultSuccess';
}
