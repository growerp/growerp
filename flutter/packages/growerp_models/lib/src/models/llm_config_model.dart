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
