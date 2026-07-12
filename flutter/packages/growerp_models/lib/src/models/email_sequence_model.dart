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
