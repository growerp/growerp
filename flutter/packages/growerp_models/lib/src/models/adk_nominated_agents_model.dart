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

part 'adk_nominated_agents_model.g.dart';

/// Support app's catalog-promotion review queue: tenant agents with
/// catalogNominated='Y' (AdkServices100.get#NominatedAgents). Reuses
/// [AdkAgentConfig] for each row (the service projects a subset of its fields,
/// which is fine since every field on that model is nullable).
@JsonSerializable(explicitToJson: true)
class AdkNominatedAgents {
  final List<AdkAgentConfig> agents;

  const AdkNominatedAgents({required this.agents});

  factory AdkNominatedAgents.fromJson(Map<String, dynamic> json) =>
      _$AdkNominatedAgentsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkNominatedAgentsToJson(this);
}
