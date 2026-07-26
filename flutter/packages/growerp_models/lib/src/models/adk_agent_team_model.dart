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

part 'adk_agent_team_model.g.dart';

/// A specialist agent that belongs to a coordinator's team (Phase 4).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkAgentTeamMember {
  final String? adkAgentTeamMemberId;
  final String? coordinatorConfigId;
  final String? memberConfigId;
  final String? memberName;
  final String? memberDescription;
  final int? sequenceNum;

  /// tool | transfer
  final String? delegationMode;
  @JsonKey(defaultValue: true)
  final bool enabled;

  const AdkAgentTeamMember({
    this.adkAgentTeamMemberId,
    this.coordinatorConfigId,
    this.memberConfigId,
    this.memberName,
    this.memberDescription,
    this.sequenceNum,
    this.delegationMode,
    this.enabled = true,
  });

  factory AdkAgentTeamMember.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTeamMemberFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentTeamMemberToJson(this);

  @override
  String toString() =>
      'AdkAgentTeamMember[$memberConfigId ($memberName) of $coordinatorConfigId]';
}

@JsonSerializable()
class AdkAgentTeamMembers {
  final List<AdkAgentTeamMember> members;

  const AdkAgentTeamMembers({this.members = const []});

  factory AdkAgentTeamMembers.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTeamMembersFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentTeamMembersToJson(this);
}
