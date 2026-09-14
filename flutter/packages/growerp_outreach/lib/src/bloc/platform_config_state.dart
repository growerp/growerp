part of 'platform_config_bloc.dart';

/// [verified] is its own status: the detail dialog pops on any [success] with a
/// message, and a credential check must leave that dialog open.
enum PlatformConfigStatus { initial, loading, success, verified, failure }

class PlatformConfigState extends Equatable {
  final PlatformConfigStatus status;
  final List<PlatformConfiguration> configs;
  final String? message;

  const PlatformConfigState({
    this.status = PlatformConfigStatus.initial,
    this.configs = const [],
    this.message,
  });

  PlatformConfigState copyWith({
    PlatformConfigStatus? status,
    List<PlatformConfiguration>? configs,
    String? message,
  }) {
    return PlatformConfigState(
      status: status ?? this.status,
      configs: configs ?? this.configs,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, configs, message];
}
