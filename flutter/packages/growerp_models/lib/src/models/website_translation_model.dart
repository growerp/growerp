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

part 'website_translation_model.freezed.dart';
part 'website_translation_model.g.dart';

/// One run of the website translator: translate an owner's website into the
/// languages the apps support. Runs in the background, so this record is polled
/// for progress.
@freezed
abstract class WebsiteTranslation with _$WebsiteTranslation {
  factory WebsiteTranslation({
    @Default('') String translationId,
    @Default('') String ownerPartyId,
    @Default('') String ownerName,
    @Default('') String productStoreId,
    @Default('') String sourceLocale,
    @Default('') String targetLocales, // comma separated
    @Default('') String translateEntityNames, // Y/N
    @Default('') String overwriteExisting, // Y/N
    // QUEUED, TRANSLATING, COMPLETED, FAILED
    @Default('') String status,
    @Default('') String statusMessage,
    int? pageCount,
    int? translatedCount,
    @Default('') String errorMessage,
    @DateTimeConverter() DateTime? createdDate,
    @DateTimeConverter() DateTime? completedDate,
  }) = _WebsiteTranslation;
  WebsiteTranslation._();

  factory WebsiteTranslation.fromJson(Map<String, dynamic> json) =>
      _$WebsiteTranslationFromJson(json['websiteTranslation'] ?? json);

  /// the languages a website can be translated into, the ones the apps support
  static const List<String> supportedLocales = ['th', 'zh', 'de', 'fr', 'nl'];

  static const Map<String, String> localeNames = {
    'en': 'English',
    'th': 'ไทย',
    'zh': '中文',
    'de': 'Deutsch',
    'fr': 'Français',
    'nl': 'Nederlands',
  };

  /// still working, so the list keeps polling
  bool get inProgress => const ['QUEUED', 'TRANSLATING'].contains(status);

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';

  List<String> get targetLocaleList => targetLocales
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// eg 'ไทย, Nederlands' for the list column
  String get targetLanguageNames =>
      targetLocaleList.map((l) => localeNames[l] ?? l).join(', ');

  @override
  String toString() =>
      'WebsiteTranslation $translationId $ownerPartyId $targetLocales $status';
}
