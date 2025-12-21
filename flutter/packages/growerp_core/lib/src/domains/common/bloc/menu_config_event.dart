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
