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

import 'package:json_annotation/json_annotation.dart';

part 'llm_config_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LlmConfig {
  final String llmProvider;
  // write-only: backend returns '****' when set; never stored locally
  final String? apiKey;

  const LlmConfig({
    required this.llmProvider,
    this.apiKey,
  });

  factory LlmConfig.fromJson(Map<String, dynamic> json) =>
      _$LlmConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LlmConfigToJson(this);

  LlmConfig copyWith({String? llmProvider, String? apiKey}) => LlmConfig(
        llmProvider: llmProvider ?? this.llmProvider,
        apiKey: apiKey ?? this.apiKey,
      );

  @override
  String toString() => 'LlmConfig[$llmProvider]';
}
