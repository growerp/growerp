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

/// Start the LinkedIn connect: emits [PlatformConfigStatus.linkedInWaiting]
/// with the consent URL for the screen to open in the browser.
class PlatformConfigLinkedInConnect extends PlatformConfigEvent {
  const PlatformConfigLinkedInConnect();
}

/// Poll while the LinkedIn sign in runs in the browser: emits
/// [PlatformConfigStatus.linkedInConnected] once the LINKEDIN configuration
/// carries a new token, nothing otherwise.
class PlatformConfigLinkedInCheck extends PlatformConfigEvent {
  const PlatformConfigLinkedInCheck();
}
