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
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../growerp_models.dart';

part 'policy_model.freezed.dart';
part 'policy_model.g.dart';

/// An insurance policy an agency sold for a carrier to an insured client.
/// Commission fields are only filled for agency staff.
@freezed
abstract class Policy with _$Policy {
  factory Policy({
    @Default("") String policyId,
    @Default("") String pseudoId,
    String? policyNumber,
    String? insuredPartyId,
    String? insuredName,
    String? carrierPartyId,
    String? carrierName,
    String? producerPartyId,
    String? producerName,
    @JsonKey(name: 'policyTypeEnumId')
    @PolicyTypeConverter()
    PolicyType? policyType,
    @JsonKey(name: 'statusId') @PolicyStatusConverter() PolicyStatus? status,
    @DateTimeConverter() DateTime? effectiveDate,
    @DateTimeConverter() DateTime? expirationDate,
    Decimal? premiumAmount,
    @JsonKey(name: 'premiumFrequencyEnumId')
    @PremiumFrequencyConverter()
    PremiumFrequency? premiumFrequency,
    String? currencyUomId,
    Decimal? commissionRate,
    Decimal? commissionExpected,
    Decimal? commissionReceived,
    String? renewedFromPolicyId,
    String? description,
    List<PolicyCoverage>? coverages,
  }) = _Policy;
  Policy._();

  factory Policy.fromJson(Map<String, dynamic> json) =>
      _$PolicyFromJson(json['policy'] ?? json);

  @override
  String toString() =>
      'Policy: $pseudoId $policyNumber $insuredName $carrierName $status';
}

@freezed
abstract class PolicyCoverage with _$PolicyCoverage {
  factory PolicyCoverage({
    String? coverageSeqId,
    String? coverageName,
    Decimal? limitAmount,
    Decimal? deductibleAmount,
  }) = _PolicyCoverage;
  PolicyCoverage._();

  factory PolicyCoverage.fromJson(Map<String, dynamic> json) =>
      _$PolicyCoverageFromJson(json);
}
