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
