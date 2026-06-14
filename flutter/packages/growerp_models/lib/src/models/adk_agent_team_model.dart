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
