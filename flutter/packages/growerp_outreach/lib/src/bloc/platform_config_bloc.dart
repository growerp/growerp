import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

part 'platform_config_event.dart';
part 'platform_config_state.dart';

class PlatformConfigBloc
    extends Bloc<PlatformConfigEvent, PlatformConfigState> {
  final RestClient restClient;

  PlatformConfigBloc(this.restClient) : super(const PlatformConfigState()) {
    on<PlatformConfigFetch>(_onPlatformConfigFetch);
    on<PlatformConfigUpdate>(_onPlatformConfigUpdate);
    on<PlatformConfigCreate>(_onPlatformConfigCreate);
    on<PlatformConfigDelete>(_onPlatformConfigDelete);
  }

  Future<void> _onPlatformConfigFetch(
    PlatformConfigFetch event,
    Emitter<PlatformConfigState> emit,
  ) async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    try {
      final response = await restClient.listPlatformConfigurations();
      emit(PlatformConfigState(
        status: PlatformConfigStatus.success,
        configs: response.configs,
        message: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlatformConfigStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPlatformConfigUpdate(
    PlatformConfigUpdate event,
    Emitter<PlatformConfigState> emit,
  ) async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    try {
      final updatedConfig = await restClient.updatePlatformConfiguration(
        configId: event.config.configId!,
        isEnabled: event.config.isEnabled ? 'Y' : 'N',
        dailyLimit: event.config.dailyLimit,
        apiKey: event.config.apiKey,
        apiSecret: event.config.apiSecret,
        username: event.config.username,
        password: event.config.password,
      );
      final updatedConfigs = state.configs.map((config) {
        return config.configId == updatedConfig.configId
            ? updatedConfig
            : config;
      }).toList();
      emit(state.copyWith(
        status: PlatformConfigStatus.success,
        configs: updatedConfigs,
        message: 'Configuration updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlatformConfigStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPlatformConfigCreate(
    PlatformConfigCreate event,
    Emitter<PlatformConfigState> emit,
  ) async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    try {
      final newConfig = await restClient.createPlatformConfiguration(
        platform: event.config.platform,
        isEnabled: event.config.isEnabled ? 'Y' : 'N',
        dailyLimit: event.config.dailyLimit,
        apiKey: event.config.apiKey,
        apiSecret: event.config.apiSecret,
        username: event.config.username,
        password: event.config.password,
      );
      emit(state.copyWith(
        status: PlatformConfigStatus.success,
        configs: List.of(state.configs)..add(newConfig),
        message: 'Configuration created successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlatformConfigStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPlatformConfigDelete(
    PlatformConfigDelete event,
    Emitter<PlatformConfigState> emit,
  ) async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    try {
      await restClient.deletePlatformConfiguration(configId: event.configId);
      final updatedConfigs = state.configs
          .where((config) => config.configId != event.configId)
          .toList();
      // Use new state with null message to not trigger detail screen pop
      emit(PlatformConfigState(
        status: PlatformConfigStatus.success,
        configs: updatedConfigs,
        message: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlatformConfigStatus.failure,
        message: e.toString(),
      ));
    }
  }
}
