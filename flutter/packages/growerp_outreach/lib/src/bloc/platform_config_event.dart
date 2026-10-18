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

/// Check the stored credentials against the platform; the result lands on the
/// configuration as lastCheckDate/lastCheckError. When [config] is given it is
/// saved first, so the check runs against what is on screen.
class PlatformConfigVerify extends PlatformConfigEvent {
  final String configId;
  final PlatformConfiguration? config;

  const PlatformConfigVerify(this.configId, {this.config});

  @override
  List<Object> get props => [configId, ?config];
}

class PlatformConfigDelete extends PlatformConfigEvent {
  final String configId;

  const PlatformConfigDelete(this.configId);

  @override
  List<Object> get props => [configId];
}
