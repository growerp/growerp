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

part 'email_template_model.freezed.dart';
part 'email_template_model.g.dart';

@freezed
abstract class EmailTemplate with _$EmailTemplate {
  factory EmailTemplate({
    @Default("") String emailTemplateId,
    String? description,
    String? emailTypeEnumId,
    String? fromAddress,
    String? fromName,
    String? subject,
    String? bodyScreenLocation,
    String? bodyContent,
    String? replyToAddresses,
    String? ccAddresses,
    String? bccAddresses,
  }) = _EmailTemplate;
  EmailTemplate._();

  factory EmailTemplate.fromJson(Map<String, dynamic> json) =>
      _$EmailTemplateFromJson(json['emailTemplate'] ?? json);

  @override
  String toString() =>
      'EmailTemplate: $emailTemplateId '
      'Description: $description '
      'Subject: $subject ';
}
