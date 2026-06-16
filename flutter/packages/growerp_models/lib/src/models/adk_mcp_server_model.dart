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

part 'adk_mcp_server_model.g.dart';

/// An external (remote) MCP server registered by a tenant. Reachable over SSE /
/// streamable-HTTP; attached to agents via [AdkAgentMcpServer].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkMcpServer {
  final String? adkMcpServerId;
  final String? serverName;
  final String? url;

  /// sse | http
  final String? transport;

  /// Auth headers (name -> value) sent on connect. Write-only: never returned
  /// by GET (stored encrypted on the server, like an api key).
  @JsonKey(includeFromJson: false)
  final Map<String, String>? headers;

  @JsonKey(defaultValue: true)
  final bool enabled;

  const AdkMcpServer({
    this.adkMcpServerId,
    this.serverName,
    this.url,
    this.transport,
    this.headers,
    this.enabled = true,
  });

  factory AdkMcpServer.fromJson(Map<String, dynamic> json) =>
      _$AdkMcpServerFromJson(json);
  Map<String, dynamic> toJson() => _$AdkMcpServerToJson(this);

  AdkMcpServer copyWith({
    String? adkMcpServerId,
    String? serverName,
    String? url,
    String? transport,
    Map<String, String>? headers,
    bool? enabled,
  }) =>
      AdkMcpServer(
        adkMcpServerId: adkMcpServerId ?? this.adkMcpServerId,
        serverName: serverName ?? this.serverName,
        url: url ?? this.url,
        transport: transport ?? this.transport,
        headers: headers ?? this.headers,
        enabled: enabled ?? this.enabled,
      );

  @override
  String toString() => 'AdkMcpServer[$adkMcpServerId: $serverName ($url)]';
}

@JsonSerializable()
class AdkMcpServers {
  final List<AdkMcpServer> adkMcpServers;

  const AdkMcpServers({this.adkMcpServers = const []});

  factory AdkMcpServers.fromJson(Map<String, dynamic> json) =>
      _$AdkMcpServersFromJson(json);
  Map<String, dynamic> toJson() => _$AdkMcpServersToJson(this);
}

/// Attachment of an [AdkMcpServer] to an agent (configId).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkAgentMcpServer {
  final String? adkAgentMcpServerId;
  final String? configId;
  final String? adkMcpServerId;
  final String? serverName;
  final String? url;
  final String? transport;
  final int? sequenceNum;
  @JsonKey(defaultValue: true)
  final bool enabled;

  const AdkAgentMcpServer({
    this.adkAgentMcpServerId,
    this.configId,
    this.adkMcpServerId,
    this.serverName,
    this.url,
    this.transport,
    this.sequenceNum,
    this.enabled = true,
  });

  factory AdkAgentMcpServer.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentMcpServerFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentMcpServerToJson(this);

  @override
  String toString() =>
      'AdkAgentMcpServer[$adkMcpServerId ($serverName) on $configId]';
}

@JsonSerializable()
class AdkAgentMcpServers {
  final List<AdkAgentMcpServer> servers;

  const AdkAgentMcpServers({this.servers = const []});

  factory AdkAgentMcpServers.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentMcpServersFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentMcpServersToJson(this);
}
