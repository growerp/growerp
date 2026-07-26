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

part 'email_sequence_model.freezed.dart';
part 'email_sequence_model.g.dart';

@freezed
abstract class EmailSequenceStep with _$EmailSequenceStep {
  EmailSequenceStep._();
  factory EmailSequenceStep({
    int? stepSeq,
    @Default(0) int delayDays,
    @Default("") String subject,
    @Default("") String bodyHtml,
  }) = _EmailSequenceStep;

  factory EmailSequenceStep.fromJson(Map<String, dynamic> json) =>
      _$EmailSequenceStepFromJson(json['step'] ?? json);
}

@freezed
abstract class EmailSequence with _$EmailSequence {
  EmailSequence._();
  factory EmailSequence({
    @Default("") String emailSequenceId,
    @Default("") String pseudoId,
    @Default("") String sequenceName,
    @Default("") String status, // ACTIVE, PAUSED
    @Default("") String marketingCampaignId,
    @Default(0) int activeEnrollments,
    @Default(0) int completedEnrollments,
    @Default([]) List<EmailSequenceStep> steps,
  }) = _EmailSequence;

  factory EmailSequence.fromJson(Map<String, dynamic> json) =>
      _$EmailSequenceFromJson(json['emailSequence'] ?? json);
}

@freezed
abstract class EmailSequences with _$EmailSequences {
  EmailSequences._();
  factory EmailSequences({
    @Default([]) List<EmailSequence> emailSequences,
  }) = _EmailSequences;

  factory EmailSequences.fromJson(Map<String, dynamic> json) =>
      _$EmailSequencesFromJson(json);
}
