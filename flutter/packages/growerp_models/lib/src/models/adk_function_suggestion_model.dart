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
import 'adk_agent_config_model.dart';

part 'adk_function_suggestion_model.g.dart';

/// Result of AdkServices100.suggest#AgentFunction: a feasibility check against
/// real services (and the session's own screen catalog) for a free-text
/// described function. Never creates anything — [draft], when present, is
/// meant to pre-fill AdkAgentConfigDialog for the admin to review and save.
@JsonSerializable(explicitToJson: true)
class AdkFunctionSuggestion {
  /// navigation | newFunction | notPossible | error
  final String outcome;
  final String message;
  final AdkAgentConfig? draft;

  const AdkFunctionSuggestion({
    required this.outcome,
    required this.message,
    this.draft,
  });

  factory AdkFunctionSuggestion.fromJson(Map<String, dynamic> json) =>
      _$AdkFunctionSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$AdkFunctionSuggestionToJson(this);
}
