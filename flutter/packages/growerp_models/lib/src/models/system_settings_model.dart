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
    // Quota
    int? llmSystemTokenLimit,
  }) = _SystemSettings;
  SystemSettings._();

  factory SystemSettings.fromJson(Map<String, dynamic> json) =>
      _$SystemSettingsFromJson(json['systemSettings'] ?? json);

  @override
  String toString() =>
      'SystemSettings smtpHost: $smtpHost storeHost: $storeHost '
      'geminiApiKey: ${geminiApiKey != null ? "set" : "unset"} '
      'githubToken: ${githubToken != null ? "set" : "unset"} '
      'githubRepository: ${githubRepository ?? "unset"} '
      'llmSystemTokenLimit: $llmSystemTokenLimit';
}
