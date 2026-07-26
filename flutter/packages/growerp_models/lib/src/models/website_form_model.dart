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

part 'website_form_model.freezed.dart';
part 'website_form_model.g.dart';

@freezed
abstract class WebsiteFormField with _$WebsiteFormField {
  WebsiteFormField._();
  factory WebsiteFormField({
    @Default("") String fieldId,
    int? sequenceNum,
    @Default("") String label,
    @Default("") String fieldType, // text, email, phone, textarea
    @Default("") String isRequired, // Y/N
  }) = _WebsiteFormField;

  factory WebsiteFormField.fromJson(Map<String, dynamic> json) =>
      _$WebsiteFormFieldFromJson(json['field'] ?? json);
}

@freezed
abstract class WebsiteForm with _$WebsiteForm {
  WebsiteForm._();
  factory WebsiteForm({
    @Default("") String formId,
    @Default("") String pseudoId,
    @Default("") String formName,
    @Default("") String title,
    @Default("") String submitLabel,
    @Default("") String successMessage,
    @Default("") String emailSequenceId,
    @Default("") String emailTemplateId,
    @Default(0) int submissionCount,
    @Default([]) List<WebsiteFormField> fields,
  }) = _WebsiteForm;

  factory WebsiteForm.fromJson(Map<String, dynamic> json) =>
      _$WebsiteFormFromJson(json['webForm'] ?? json);
}

@freezed
abstract class WebsiteForms with _$WebsiteForms {
  WebsiteForms._();
  factory WebsiteForms({@Default([]) List<WebsiteForm> webForms}) =
      _WebsiteForms;

  factory WebsiteForms.fromJson(Map<String, dynamic> json) =>
      _$WebsiteFormsFromJson(json);
}
