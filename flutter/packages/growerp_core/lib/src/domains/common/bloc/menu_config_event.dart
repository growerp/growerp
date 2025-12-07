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
  const MenuConfigLoad({this.appId, this.userId, this.forceRefresh = false});

  final String? appId;
  final String? userId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [appId, userId, forceRefresh];
}

/// Update local menu configuration (without backend call)
class MenuConfigUpdateLocal extends MenuConfigEvent {
  const MenuConfigUpdateLocal(this.menuConfiguration);

  final MenuConfiguration menuConfiguration;

  @override
  List<Object?> get props => [menuConfiguration];
}

/// Create new menu option (main menu entry)
class MenuOptionCreate extends MenuConfigEvent {
  const MenuOptionCreate({
    required this.menuConfigurationId,
    required this.menuOption,
  });

  final String menuConfigurationId;
  final MenuOption menuOption;

  @override
  List<Object?> get props => [menuConfigurationId, menuOption];
}

/// Update existing menu option
class MenuOptionUpdate extends MenuConfigEvent {
  const MenuOptionUpdate({
    required this.menuOptionId,
    required this.menuOption,
  });

  final String menuOptionId;
  final MenuOption menuOption;

  @override
  List<Object?> get props => [menuOptionId, menuOption];
}

/// Delete menu option
class MenuOptionDelete extends MenuConfigEvent {
  const MenuOptionDelete(this.menuOptionId);

  final String menuOptionId;

  @override
  List<Object?> get props => [menuOptionId];
}

/// Reorder menu options (drag and drop)
class MenuOptionsReorder extends MenuConfigEvent {
  const MenuOptionsReorder({
    required this.menuConfigurationId,
    required this.optionSequences,
  });

  final String menuConfigurationId;
  final List<Map<String, dynamic>> optionSequences;

  @override
  List<Object?> get props => [menuConfigurationId, optionSequences];
}

/// Toggle menu option active status
class MenuOptionToggleActive extends MenuConfigEvent {
  const MenuOptionToggleActive(this.menuOptionId);

  final String menuOptionId;

  @override
  List<Object?> get props => [menuOptionId];
}

/// Link a MenuItem (tab) to a MenuOption
class MenuItemLink extends MenuConfigEvent {
  const MenuItemLink({
    required this.menuOptionId,
    required this.menuItemId,
    this.sequenceNum,
  });

  final String menuOptionId;
  final String menuItemId;
  final int? sequenceNum;

  @override
  List<Object?> get props => [menuOptionId, menuItemId, sequenceNum];
}

/// Unlink a MenuItem (tab) from a MenuOption
class MenuItemUnlink extends MenuConfigEvent {
  const MenuItemUnlink({required this.menuOptionId, required this.menuItemId});

  final String menuOptionId;
  final String menuItemId;

  @override
  List<Object?> get props => [menuOptionId, menuItemId];
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
