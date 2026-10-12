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

import '../../growerp_models.dart';

part 'renewal_model.freezed.dart';
part 'renewal_model.g.dart';

/// A policy to renew with its explainable lead score and the next best
/// step (channel, action, time). Also a row of the telesales queue, then
/// with [reason], [requestedDate] and the [aiSummary] of the AI call.
@freezed
abstract class RenewalCandidate with _$RenewalCandidate {
  factory RenewalCandidate({
    @Default("") String policyId,
    String? pseudoId,
    String? policyNumber,
    String? insuredPartyId,
    String? insuredName,
    String? vehiclePlate,
    String? vehicleDescription,
    String? policyTypeEnumId,
    String? statusId,
    @DateTimeConverter() DateTime? expirationDate,
    int? daysToExpiry,
    int? score,
    String? band,
    List<String>? reasons,
    String? nextChannelEnumId,
    String? nextAction,
    String? nextTime,
    int? completeness,
    List<String>? missing,
    String? stage,
    List<String>? consentChannels,
    String? lastEventEnumId,
    String? lastChannelEnumId,
    @DateTimeConverter() DateTime? lastTouchDate,
    int? touchCount,
    String? reason,
    @DateTimeConverter() DateTime? requestedDate,
    String? aiSummary,
    String? aiChannelEnumId,
  }) = _RenewalCandidate;
  RenewalCandidate._();

  factory RenewalCandidate.fromJson(Map<String, dynamic> json) =>
      _$RenewalCandidateFromJson(json);
}

@freezed
abstract class RenewalCandidates with _$RenewalCandidates {
  factory RenewalCandidates({
    @Default([]) List<RenewalCandidate> candidates,
    @Default([]) List<RenewalCandidate> queue,
  }) = _RenewalCandidates;
  RenewalCandidates._();

  factory RenewalCandidates.fromJson(Map<String, dynamic> json) =>
      _$RenewalCandidatesFromJson(json);
}

/// One step of a renewal journey: a reminder, the customer's reaction, a
/// call and its outcome.
@freezed
abstract class RenewalTouch with _$RenewalTouch {
  factory RenewalTouch({
    @Default("") String touchId,
    String? channelEnumId,
    String? eventEnumId,
    String? outcomeEnumId,
    @DateTimeConverter() DateTime? touchDate,
    String? messageText,
    String? summary,
    String? transcript,
  }) = _RenewalTouch;
  RenewalTouch._();

  factory RenewalTouch.fromJson(Map<String, dynamic> json) =>
      _$RenewalTouchFromJson(json);
}

@freezed
abstract class RenewalTouches with _$RenewalTouches {
  factory RenewalTouches({@Default([]) List<RenewalTouch> touches}) =
      _RenewalTouches;
  RenewalTouches._();

  factory RenewalTouches.fromJson(Map<String, dynamic> json) =>
      _$RenewalTouchesFromJson(json);
}
