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

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../growerp_models.dart';

part 'claim_model.freezed.dart';
part 'claim_model.g.dart';

/// A claim of an insured client on a policy, followed up by the agency with
/// the carrier.
@freezed
abstract class Claim with _$Claim {
  factory Claim({
    @Default("") String claimId,
    @Default("") String pseudoId,
    @Default("") String policyId,
    String? policyPseudoId,
    String? policyNumber,
    String? insuredName,
    String? carrierName,
    String? claimNumber,
    @JsonKey(name: 'statusId') @ClaimStatusConverter() ClaimStatus? status,
    @JsonKey(name: 'incidentTypeEnumId')
    @IncidentTypeConverter()
    IncidentType? incidentType,
    @DateTimeConverter() DateTime? incidentDate,
    String? incidentLocation,
    @DateTimeConverter() DateTime? reportedDate,
    String? description,
    Decimal? amountClaimed,
    Decimal? amountPaid,
    String? comments,
    String? aiAssessment,
    @DateTimeConverter() DateTime? aiAssessedDate,
    List<String>? missingEvidence,
    List<ClaimPhoto>? photos,
    List<ClaimStatusChange>? statusHistory,
  }) = _Claim;
  Claim._();

  factory Claim.fromJson(Map<String, dynamic> json) =>
      _$ClaimFromJson(json['claim'] ?? json);

  @override
  String toString() => 'Claim: $pseudoId policy $policyPseudoId $status';
}

/// A photo of a claim; [image] is only filled when the claim is read by id,
/// or when a new photo is uploaded.
@freezed
abstract class ClaimPhoto with _$ClaimPhoto {
  factory ClaimPhoto({
    String? contentSeqId,
    String? description,
    @Uint8ListConverter() Uint8List? image,
  }) = _ClaimPhoto;
  ClaimPhoto._();

  factory ClaimPhoto.fromJson(Map<String, dynamic> json) =>
      _$ClaimPhotoFromJson(json);
}

/// One step of the claim status timeline, from the status audit log.
@freezed
abstract class ClaimStatusChange with _$ClaimStatusChange {
  factory ClaimStatusChange({
    @JsonKey(name: 'statusId') @ClaimStatusConverter() ClaimStatus? status,
    @DateTimeConverter() DateTime? changedDate,
  }) = _ClaimStatusChange;
  ClaimStatusChange._();

  factory ClaimStatusChange.fromJson(Map<String, dynamic> json) =>
      _$ClaimStatusChangeFromJson(json);
}
