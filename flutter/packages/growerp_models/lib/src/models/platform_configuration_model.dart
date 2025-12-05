import 'package:json_annotation/json_annotation.dart';

part 'platform_configuration_model.g.dart';

/// Platform Configuration model
@JsonSerializable()
class PlatformConfiguration {
  /// Config unique identifier
  final String? configId;

  /// Owner party ID
  final String? ownerPartyId;

  /// Platform name: EMAIL, LINKEDIN, TWITTER, etc.
  final String platform;

  /// Whether platform is enabled
  final bool isEnabled;

  /// Daily limit for this platform
  final int dailyLimit;

  /// API Key for platform authentication
  final String? apiKey;

  /// API Secret for platform authentication
  final String? apiSecret;

  /// Username for platform authentication
  final String? username;

  /// Password for platform authentication
  final String? password;

  /// Last time platform was used
  final DateTime? lastUsedDate;

  const PlatformConfiguration({
    this.configId,
    this.ownerPartyId,
    required this.platform,
    this.isEnabled = false,
    this.dailyLimit = 50,
    this.apiKey,
    this.apiSecret,
    this.username,
    this.password,
    this.lastUsedDate,
  });

  factory PlatformConfiguration.fromJson(Map<String, dynamic> json) =>
      _$PlatformConfigurationFromJson(json['config'] ?? json);

  Map<String, dynamic> toJson() => _$PlatformConfigurationToJson(this);

  @override
  String toString() => 'PlatformConfiguration($platform, enabled: $isEnabled)';
}
