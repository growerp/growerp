/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:dio/dio.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../services/get_dio_error.dart';

part 'menu_config_event.dart';
part 'menu_config_state.dart';

EventTransformer<E> menuConfigDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// MenuConfigBloc manages menu configuration state
///
/// Handles loading menu configurations from backend, caching them locally,
/// and managing user customizations. Supports both default app menus and
/// user-specific menu overrides.
///
class MenuConfigBloc extends Bloc<MenuConfigEvent, MenuConfigState> {
  MenuConfigBloc(this.restClient, this.appId) : super(const MenuConfigState()) {
    on<MenuConfigLoad>(_onMenuConfigLoad);
    on<MenuConfigUpdateLocal>(_onMenuConfigUpdateLocal);
    on<MenuItemCreate>(_onMenuItemCreate);
    on<MenuItemUpdate>(_onMenuItemUpdate);
    on<MenuItemDelete>(_onMenuItemDelete);
    on<MenuItemsReorder>(
      _onMenuItemsReorder,
      transformer: menuConfigDroppable(const Duration(milliseconds: 300)),
    );
    on<MenuItemToggleActive>(_onMenuItemToggleActive);
    on<MenuItemLink>(_onMenuItemLink);
    on<MenuItemUnlink>(_onMenuItemUnlink);
    on<MenuConfigClone>(_onMenuConfigClone);
    on<MenuConfigSave>(_onMenuConfigSave);
    on<MenuConfigReset>(_onMenuConfigReset);
  }

  final RestClient restClient;
  final String appId;

  /// Load menu configuration from backend or cache
  Future<void> _onMenuConfigLoad(
    MenuConfigLoad event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      // Use provided appId or default from bloc
      final targetAppId = event.appId ?? appId;

      // Load menu configuration from backend
      final menuConfig = await restClient.getMenuConfiguration(
        appId: targetAppId,
        userVersion: event.userVersion ? true : null,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Update local menu configuration without backend call
  void _onMenuConfigUpdateLocal(
    MenuConfigUpdateLocal event,
    Emitter<MenuConfigState> emit,
  ) {
    emit(
      state.copyWith(
        status: MenuConfigStatus.success,
        menuConfiguration: event.menuConfiguration,
      ),
    );
  }

  /// Create new menu option (main menu entry)
  Future<void> _onMenuItemCreate(
    MenuItemCreate event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.createMenuItem(
        menuConfigurationId: event.menuConfigurationId,
        itemKey: event.menuOption.itemKey,
        title: event.menuOption.title,
        route: event.menuOption.route,
        iconName: event.menuOption.iconName,
        widgetName: event.menuOption.widgetName,
        image: event.menuOption.image,
        selectedImage: event.menuOption.selectedImage,
        userGroupsJson: event.menuOption.userGroups?.toString(),
        sequenceNum: event.menuOption.sequenceNum,
        isActive: event.menuOption.isActive ? 'Y' : 'N',
      );

      // Reload menu configuration with userVersion=true to get user-specific config
      // (backend may have cloned seed data to a new user-specific config)
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu option created successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Update existing menu option
  Future<void> _onMenuItemUpdate(
    MenuItemUpdate event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.updateMenuItem(
        menuItemId: event.menuItemId,
        itemKey: event.menuOption.itemKey,
        title: event.menuOption.title,
        route: event.menuOption.route,
        iconName: event.menuOption.iconName,
        widgetName: event.menuOption.widgetName,
        image: event.menuOption.image,
        selectedImage: event.menuOption.selectedImage,
        userGroupsJson: event.menuOption.userGroups?.toString(),
        sequenceNum: event.menuOption.sequenceNum,
        isActive: event.menuOption.isActive ? 'Y' : 'N',
      );

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu option updated successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Delete menu option
  Future<void> _onMenuItemDelete(
    MenuItemDelete event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.deleteMenuItem(menuItemId: event.menuItemId);

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu option deleted successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Reorder menu options (for drag and drop)
  Future<void> _onMenuItemsReorder(
    MenuItemsReorder event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.reorderMenuItems(
        menuConfigurationId: event.menuConfigurationId,
        itemSequences: event.optionSequences,
      );

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu options reordered successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Toggle menu option active status
  Future<void> _onMenuItemToggleActive(
    MenuItemToggleActive event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.toggleMenuItemActive(menuItemId: event.menuItemId);

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu option visibility toggled',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Add a child MenuItem (tab) to a parent MenuItem
  /// In the unified model, this creates a new MenuItem with parentMenuItemId set
  Future<void> _onMenuItemLink(
    MenuItemLink event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.createMenuItem(
        menuConfigurationId: state.menuConfiguration!.menuConfigurationId!,
        parentMenuItemId: event.parentMenuItemId,
        title: event.title ?? 'New Tab',
        widgetName: event.widgetName,
        sequenceNum: event.sequenceNum,
      );

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Child menu item added successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Remove a child MenuItem (tab) from a parent MenuItem
  /// In the unified model, this deletes the child MenuItem
  Future<void> _onMenuItemUnlink(
    MenuItemUnlink event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.deleteMenuItem(menuItemId: event.childMenuItemId);

      // Reload menu configuration with userVersion=true to get user-specific config
      final menuConfig = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Child menu item removed successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Clone menu configuration for user customization
  Future<void> _onMenuConfigClone(
    MenuConfigClone event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      final clonedConfig = await restClient.cloneMenuConfiguration(
        sourceMenuConfigurationId: event.sourceMenuConfigurationId,
        name: event.name,
      );

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: clonedConfig,
          message: 'Menu configuration cloned successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Save menu configuration to backend
  Future<void> _onMenuConfigSave(
    MenuConfigSave event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      if (event.menuConfiguration.menuConfigurationId == null) {
        // Create new configuration
        final createdConfig = await restClient.createMenuConfiguration(
          appId: event.menuConfiguration.appId,
          userId: event.menuConfiguration.userId,
          name: event.menuConfiguration.name,
          description: event.menuConfiguration.description,
        );

        emit(
          state.copyWith(
            status: MenuConfigStatus.success,
            menuConfiguration: createdConfig,
            message: 'Menu configuration created successfully',
          ),
        );
      } else {
        // Update existing configuration
        final updatedConfig = await restClient.updateMenuConfiguration(
          menuConfigurationId: event.menuConfiguration.menuConfigurationId!,
          name: event.menuConfiguration.name,
          description: event.menuConfiguration.description,
        );

        emit(
          state.copyWith(
            status: MenuConfigStatus.success,
            menuConfiguration: updatedConfig,
            message: 'Menu configuration updated successfully',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Reset menu configuration to default
  Future<void> _onMenuConfigReset(
    MenuConfigReset event,
    Emitter<MenuConfigState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MenuConfigStatus.loading));

      await restClient.resetMenuConfiguration(
        menuConfigurationId: event.menuConfigurationId,
      );

      // Reload menu configuration by appId to get the seed data after reset
      // (user config was deleted, so we need seed data)
      final menuConfig = await restClient.getMenuConfiguration(appId: appId);

      emit(
        state.copyWith(
          status: MenuConfigStatus.success,
          menuConfiguration: menuConfig,
          message: 'Menu configuration reset to default',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: MenuConfigStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
