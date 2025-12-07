/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:json_annotation/json_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'menu_option_model.g.dart';

/// Helper functions for isActive Y/N conversion
bool _isActiveFromJson(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is String) return value.toUpperCase() == 'Y';
  return true;
}

String _isActiveToJson(bool value) => value ? 'Y' : 'N';

/// MenuOption model for dynamic menu system
/// Represents main menu entries linked to a configuration
@JsonSerializable(explicitToJson: true)
class MenuOption {
  final String? menuOptionId;
  final String? menuConfigurationId;
  final String? itemKey;
  final String title;
  final String? route;
  final String? iconName;
  final String? widgetName;
  final String? image;
  final String? selectedImage;
  final List<UserGroup>? userGroups;
  final int sequenceNum;
  @JsonKey(fromJson: _isActiveFromJson, toJson: _isActiveToJson)
  final bool isActive;

  /// Child menu items (tabs) loaded from MenuOptionItem junction
  final List<MenuItem>? children;

  const MenuOption({
    this.menuOptionId,
    this.menuConfigurationId,
    this.itemKey,
    required this.title,
    this.route,
    this.iconName,
    this.widgetName,
    this.image,
    this.selectedImage,
    this.userGroups,
    this.sequenceNum = 10,
    this.isActive = true,
    this.children,
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) =>
      _$MenuOptionFromJson(json);

  Map<String, dynamic> toJson() => _$MenuOptionToJson(this);

  MenuOption copyWith({
    String? menuOptionId,
    String? menuConfigurationId,
    String? itemKey,
    String? title,
    String? route,
    String? iconName,
    String? widgetName,
    String? image,
    String? selectedImage,
    List<UserGroup>? userGroups,
    int? sequenceNum,
    bool? isActive,
    List<MenuItem>? children,
  }) {
    return MenuOption(
      menuOptionId: menuOptionId ?? this.menuOptionId,
      menuConfigurationId: menuConfigurationId ?? this.menuConfigurationId,
      itemKey: itemKey ?? this.itemKey,
      title: title ?? this.title,
      route: route ?? this.route,
      iconName: iconName ?? this.iconName,
      widgetName: widgetName ?? this.widgetName,
      image: image ?? this.image,
      selectedImage: selectedImage ?? this.selectedImage,
      userGroups: userGroups ?? this.userGroups,
      sequenceNum: sequenceNum ?? this.sequenceNum,
      isActive: isActive ?? this.isActive,
      children: children ?? this.children,
    );
  }
}

/// Wrapper for list responses
@JsonSerializable(explicitToJson: true)
class MenuOptions {
  @JsonKey(name: 'menuOption')
  final List<MenuOption> menuOptions;

  const MenuOptions({this.menuOptions = const []});

  factory MenuOptions.fromJson(Map<String, dynamic> json) =>
      _$MenuOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$MenuOptionsToJson(this);
}
