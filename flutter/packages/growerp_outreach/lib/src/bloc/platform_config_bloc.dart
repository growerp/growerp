import 'dart:convert';

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
    on<PlatformConfigVerify>(_onPlatformConfigVerify);
    on<PlatformConfigDelete>(_onPlatformConfigDelete);
    on<PlatformConfigLinkedInConnect>(_onLinkedInConnect);
    on<PlatformConfigLinkedInCheck>(_onLinkedInCheck);
  }

  /// Token expiry of the LINKEDIN row when the connect started: a different
  /// one means the backend stored a new token.
  DateTime? _linkedInExpireBefore;

  PlatformConfiguration? _linkedIn(List<PlatformConfiguration> configs) {
    for (final config in configs) {
      if (config.platform.toUpperCase() == 'LINKEDIN') return config;
    }
    return null;
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

  /// Save the on-screen values when given, probe the platform with the stored
  /// credentials, then reload the list so
  /// the row carries the fresh lastCheckDate/lastCheckError. Emits [verified],
  /// never [success]: a success with a message closes the detail dialog.
  Future<void> _onPlatformConfigVerify(
    PlatformConfigVerify event,
    Emitter<PlatformConfigState> emit,
  ) async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    try {
      final config = event.config;
      if (config != null) {
        await restClient.updatePlatformConfiguration(
          configId: event.configId,
          isEnabled: config.isEnabled ? 'Y' : 'N',
          dailyLimit: config.dailyLimit,
          apiKey: config.apiKey,
          apiSecret: config.apiSecret,
          username: config.username,
          password: config.password,
        );
      }
      dynamic result = await restClient.verifyPlatformConfiguration(
        configId: event.configId,
      );
      // dio can hand back the body as a raw JSON string
      if (result is String) result = jsonDecode(result);
      final message = result['message']?.toString() ?? '';
      final response = await restClient.listPlatformConfigurations();
      emit(PlatformConfigState(
        status: PlatformConfigStatus.verified,
        configs: response.configs,
        message: message,
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

  Future<void> _onLinkedInConnect(
    PlatformConfigLinkedInConnect event,
    Emitter<PlatformConfigState> emit,
  ) async {
    try {
      _linkedInExpireBefore = _linkedIn(state.configs)?.apiKeyExpireDate;
      dynamic result = await restClient.startLinkedInSignIn();
      // dio can hand back the body as a raw JSON string
      if (result is String) result = jsonDecode(result);
      final authUrl = result['authUrl']?.toString() ?? '';
      if (authUrl.isEmpty) throw 'no LinkedIn sign in url';
      emit(state.copyWith(
        status: PlatformConfigStatus.linkedInWaiting,
        authUrl: authUrl,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlatformConfigStatus.failure,
        message: e.toString(),
      ));
    }
  }

  /// Emits nothing until the LINKEDIN row carries a new token expiry.
  Future<void> _onLinkedInCheck(
    PlatformConfigLinkedInCheck event,
    Emitter<PlatformConfigState> emit,
  ) async {
    try {
      final response = await restClient.listPlatformConfigurations();
      final linkedIn = _linkedIn(response.configs);
      if (linkedIn?.apiKeyExpireDate == null ||
          linkedIn!.apiKeyExpireDate == _linkedInExpireBefore) {
        return;
      }
      emit(PlatformConfigState(
        status: PlatformConfigStatus.linkedInConnected,
        configs: response.configs,
        message: 'LinkedIn connected',
      ));
    } catch (_) {
      // try again on the next poll
    }
  }
}
