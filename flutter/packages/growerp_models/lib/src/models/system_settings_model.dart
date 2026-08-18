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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'llm_config_model.dart';

part 'system_settings_model.freezed.dart';
part 'system_settings_model.g.dart';

@freezed
abstract class SystemSettings with _$SystemSettings {
  factory SystemSettings({
    // Deprecated: migrated to llmConfigs. Kept nullable for pre-migration servers.
    String? geminiApiKey,
    @Default([]) List<LlmConfig> llmConfigs,
    // SMTP
    String? smtpHost,
    String? smtpPort,
    @Default('N') String smtpStartTls,
    @Default('N') String smtpSsl,
    // IMAP / store
    String? storeHost,
    String? storePort,
    @Default('imaps') String storeProtocol,
    @Default('INBOX') String storeFolder,
    @Default('N') String storeDelete,
    @Default('Y') String storeMarkSeen,
    @Default('Y') String storeSkipSeen,
    // Credentials
    String? mailUsername,
    // write-only: backend returns '****' when set; never stored locally
    String? mailPassword,
    // GitHub
    String? githubToken,
    String? githubRepository,
    // Google Workspace (calendar booking capture + Gemini meeting notes)
    String? googleClientId,
    // write-only: backend returns '****' when set
    String? googleClientSecret,
    // write-only: backend returns '****' when set
    String? googleRefreshToken,
    String? googleCalendarId,
    // Hotel: lodging/tourist tax charged per room per night
    @JsonKey(fromJson: _decimalFromJson) Decimal? touristTaxPerNight,
    // Tenant-wide default model for AI content generation; empty uses the system default.
    String? aiModelName,
    // Provider serving aiModelName: gemini, anthropic or openai.
    String? aiProvider,
  }) = _SystemSettings;
  SystemSettings._();

  factory SystemSettings.fromJson(Map<String, dynamic> json) =>
      _$SystemSettingsFromJson(json['systemSettings'] ?? json);

  @override
  String toString() =>
      'SystemSettings smtpHost: $smtpHost storeHost: $storeHost '
      'geminiApiKey: ${geminiApiKey != null ? "set" : "unset"} '
      'githubToken: ${githubToken != null ? "set" : "unset"} '
      'githubRepository: ${githubRepository ?? "unset"}';
}

Decimal? _decimalFromJson(dynamic value) {
  if (value == null) return null;
  return Decimal.parse(value.toString());
}
