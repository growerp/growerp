import 'package:json_annotation/json_annotation.dart';
import 'platform_configuration_model.dart';

part 'platform_configurations_model.g.dart';

/// Platform Configurations wrapper model
@JsonSerializable()
class PlatformConfigurations {
  /// List of platform configurations
  final List<PlatformConfiguration> configs;

  const PlatformConfigurations({this.configs = const []});

  factory PlatformConfigurations.fromJson(Map<String, dynamic> json) =>
      _$PlatformConfigurationsFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformConfigurationsToJson(this);
}
