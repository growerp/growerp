/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:json_annotation/json_annotation.dart';
import 'agent_instance_model.dart';

part 'agent_instances_model.g.dart';

/// Wrapper model for list of agent instances from REST API
@JsonSerializable(explicitToJson: true)
class AgentInstances {
  final List<AgentInstance>? agents;
  final int? totalCount;

  const AgentInstances({this.agents, this.totalCount});

  factory AgentInstances.fromJson(Map<String, dynamic> json) =>
      _$AgentInstancesFromJson(json);

  Map<String, dynamic> toJson() => _$AgentInstancesToJson(this);
}
