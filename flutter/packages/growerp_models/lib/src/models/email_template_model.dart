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
