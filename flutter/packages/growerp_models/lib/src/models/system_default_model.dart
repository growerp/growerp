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

part 'system_default_model.freezed.dart';
part 'system_default_model.g.dart';

/// GrowERP wide defaults, maintained by system support in the support app.
@freezed
abstract class SystemDefault with _$SystemDefault {
  factory SystemDefault({
    // Free system LLM tokens per tenant per calendar month; empty/0 = unlimited
    int? llmMonthlyTokenLimit,
    // GrowERP wide default model for AI content generation, used by tenants that
    // did not pick one of their own; empty falls back to the built-in default.
    @Default('') String aiModelName,
    // Provider serving aiModelName: gemini, anthropic or openai.
    @Default('') String aiProvider,
  }) = _SystemDefault;
  SystemDefault._();

  factory SystemDefault.fromJson(Map<String, dynamic> json) =>
      _$SystemDefaultFromJson(json['systemDefault'] ?? json);

  @override
  String toString() => 'SystemDefault llmMonthlyTokenLimit: $llmMonthlyTokenLimit '
      'aiModelName: $aiModelName aiProvider: $aiProvider';
}
