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

part 'gl_account_translation_model.freezed.dart';
part 'gl_account_translation_model.g.dart';

/// The GL account names translated into one language. There is no translation
/// record on the backend: a language is described by how many of the account
/// names it covers, so this is a progress row, refreshed while a run is busy.
@freezed
abstract class GlAccountTranslation with _$GlAccountTranslation {
  factory GlAccountTranslation({
    @Default('') String locale,
    @Default('') String language,
    @Default(0) int nameCount,
    @Default(0) int translatedCount,
    // not translated, partial, translated
    @Default('') String status,
  }) = _GlAccountTranslation;
  GlAccountTranslation._();

  factory GlAccountTranslation.fromJson(Map<String, dynamic> json) =>
      _$GlAccountTranslationFromJson(json['glAccountTranslation'] ?? json);

  /// the languages the account names can be translated into and from,
  /// the ones the apps support
  static const Map<String, String> localeNames = {
    'en': 'English',
    'th': 'ไทย',
    'zh': '中文',
    'de': 'Deutsch',
    'fr': 'Français',
    'nl': 'Nederlands',
  };

  bool get isCompleted => nameCount > 0 && translatedCount >= nameCount;

  @override
  String toString() =>
      'GlAccountTranslation $locale $translatedCount/$nameCount';
}
