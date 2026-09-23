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

part 'adk_agent_catalog_model.g.dart';

/// One candidate function in the shared "_NA_" agent catalog (an AdkAgentConfig
/// template row), plus whether the calling tenant already has it.
@JsonSerializable()
class AdkAgentCatalogFunction {
  final String adkAgentConfigId;
  final String agentName;
  final String? teamName;
  final String? description;
  final String? toolMode;
  final String? writePolicy;
  final bool scheduleEnabled;
  final String? agentRole;
  final bool alreadyEnabled;

  const AdkAgentCatalogFunction({
    required this.adkAgentConfigId,
    required this.agentName,
    this.teamName,
    this.description,
    this.toolMode,
    this.writePolicy,
    this.scheduleEnabled = false,
    this.agentRole,
    this.alreadyEnabled = false,
  });

  factory AdkAgentCatalogFunction.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentCatalogFunctionFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentCatalogFunctionToJson(this);
}

@JsonSerializable()
class AdkAgentCatalog {
  final List<AdkAgentCatalogFunction> functions;

  const AdkAgentCatalog({required this.functions});

  factory AdkAgentCatalog.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentCatalogFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentCatalogToJson(this);
}
