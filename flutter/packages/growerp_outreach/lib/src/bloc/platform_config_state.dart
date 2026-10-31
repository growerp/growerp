part of 'platform_config_bloc.dart';

/// [verified] is its own status: the detail dialog pops on any [success] with a
/// message, and a credential check must leave that dialog open. The same holds
/// for the LinkedIn connect: [linkedInWaiting] carries the consent [authUrl] the
/// screen opens, [linkedInConnected] follows once the backend stored the token.
enum PlatformConfigStatus {
  initial,
  loading,
  success,
  verified,
  linkedInWaiting,
  linkedInConnected,
  failure,
}

class PlatformConfigState extends Equatable {
  final PlatformConfigStatus status;
  final List<PlatformConfiguration> configs;
  final String? message;
  final String? authUrl;

  const PlatformConfigState({
    this.status = PlatformConfigStatus.initial,
    this.configs = const [],
    this.message,
    this.authUrl,
  });

  PlatformConfigState copyWith({
    PlatformConfigStatus? status,
    List<PlatformConfiguration>? configs,
    String? message,
    String? authUrl,
  }) {
    return PlatformConfigState(
      status: status ?? this.status,
      configs: configs ?? this.configs,
      message: message ?? this.message,
      authUrl: authUrl ?? this.authUrl,
    );
  }

  @override
  List<Object?> get props => [status, configs, message, authUrl];
}
