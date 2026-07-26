/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of 'menu_config_bloc.dart';

abstract class MenuConfigEvent extends Equatable {
  const MenuConfigEvent();
  @override
  List<Object?> get props => [];
}

/// Load menu configuration for the current app
class MenuConfigLoad extends MenuConfigEvent {
  const MenuConfigLoad({
    this.appId,
    this.userVersion = false,
    this.forceRefresh = false,
  });

  final String? appId;
  final bool userVersion;
  final bool forceRefresh;

  @override
  List<Object?> get props => [appId, userVersion, forceRefresh];
}

/// Update local menu configuration (without backend call)
class MenuConfigUpdateLocal extends MenuConfigEvent {
  const MenuConfigUpdateLocal(this.menuConfiguration);

  final MenuConfiguration menuConfiguration;

  @override
  List<Object?> get props => [menuConfiguration];
}

/// Create new menu option (main menu entry)
class MenuItemCreate extends MenuConfigEvent {
  const MenuItemCreate({
    required this.menuConfigurationId,
    required this.menuOption,
  });

  final String menuConfigurationId;
  final MenuItem menuOption;

  @override
  List<Object?> get props => [menuConfigurationId, menuOption];
}

/// Update existing menu option
class MenuItemUpdate extends MenuConfigEvent {
  const MenuItemUpdate({required this.menuItemId, required this.menuOption});

  final String menuItemId;
  final MenuItem menuOption;

  @override
  List<Object?> get props => [menuItemId, menuOption];
}

/// Delete menu option
class MenuItemDelete extends MenuConfigEvent {
  const MenuItemDelete(this.menuItemId);

  final String menuItemId;

  @override
  List<Object?> get props => [menuItemId];
}

/// Reorder menu options (drag and drop)
class MenuItemsReorder extends MenuConfigEvent {
  const MenuItemsReorder({
    required this.menuConfigurationId,
    required this.optionSequences,
  });

  final String menuConfigurationId;
  final List<Map<String, dynamic>> optionSequences;

  @override
  List<Object?> get props => [menuConfigurationId, optionSequences];
}

/// Toggle menu option active status
class MenuItemToggleActive extends MenuConfigEvent {
  const MenuItemToggleActive(this.menuItemId);

  final String menuItemId;

  @override
  List<Object?> get props => [menuItemId];
}

/// Toggle menu item minimized state on the dashboard
/// Minimized items are hidden from drawer/nav-rail and moved to end of dashboard
class MenuItemToggleMinimize extends MenuConfigEvent {
  const MenuItemToggleMinimize(this.menuItemId);

  final String menuItemId;

  @override
  List<Object?> get props => [menuItemId];
}

/// Add a child MenuItem (tab) to a parent MenuItem
class MenuItemLink extends MenuConfigEvent {
  const MenuItemLink({
    required this.parentMenuItemId,
    this.sequenceNum,
    this.title,
    this.widgetName,
  });

  final String parentMenuItemId;
  final int? sequenceNum;
  final String? title;
  final String? widgetName;

  @override
  List<Object?> get props => [parentMenuItemId, sequenceNum, title, widgetName];
}

/// Remove a child MenuItem (tab) from parent
class MenuItemUnlink extends MenuConfigEvent {
  const MenuItemUnlink({required this.childMenuItemId});

  final String childMenuItemId;

  @override
  List<Object?> get props => [childMenuItemId];
}

/// Clone menu configuration for user customization
class MenuConfigClone extends MenuConfigEvent {
  const MenuConfigClone({required this.sourceMenuConfigurationId, this.name});

  final String sourceMenuConfigurationId;
  final String? name;

  @override
  List<Object?> get props => [sourceMenuConfigurationId, name];
}

/// Save current menu configuration to backend
class MenuConfigSave extends MenuConfigEvent {
  const MenuConfigSave(this.menuConfiguration);

  final MenuConfiguration menuConfiguration;

  @override
  List<Object?> get props => [menuConfiguration];
}

/// Reset menu configuration to default (copies items from default app config)
class MenuConfigReset extends MenuConfigEvent {
  const MenuConfigReset(this.menuConfigurationId);

  final String menuConfigurationId;

  @override
  List<Object?> get props => [menuConfigurationId];
}
