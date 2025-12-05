part of 'platform_config_bloc.dart';

abstract class PlatformConfigEvent extends Equatable {
  const PlatformConfigEvent();

  @override
  List<Object> get props => [];
}

class PlatformConfigFetch extends PlatformConfigEvent {
  const PlatformConfigFetch();
}

class PlatformConfigUpdate extends PlatformConfigEvent {
  final PlatformConfiguration config;

  const PlatformConfigUpdate(this.config);

  @override
  List<Object> get props => [config];
}

class PlatformConfigCreate extends PlatformConfigEvent {
  final PlatformConfiguration config;

  const PlatformConfigCreate(this.config);

  @override
  List<Object> get props => [config];
}

class PlatformConfigDelete extends PlatformConfigEvent {
  final String configId;

  const PlatformConfigDelete(this.configId);

  @override
  List<Object> get props => [configId];
}
