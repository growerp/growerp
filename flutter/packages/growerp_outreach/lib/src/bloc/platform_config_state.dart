part of 'platform_config_bloc.dart';

enum PlatformConfigStatus { initial, loading, success, failure }

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
