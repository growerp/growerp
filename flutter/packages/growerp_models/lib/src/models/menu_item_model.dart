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

part 'menu_item_model.g.dart';

/// Helper functions for isActive Y/N conversion
bool _isActiveFromJson(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is String) return value.toUpperCase() == 'Y';
  return true;
}

String _isActiveToJson(bool value) => value ? 'Y' : 'N';

/// Unified MenuItem model for dynamic menu system
/// Supports recursive hierarchy via parentMenuItemId and children
/// Replaces the former separate MenuOption and MenuItem models
@JsonSerializable(explicitToJson: true)
class MenuItem {
  final String? menuItemId;
  final String? menuConfigurationId;
  final String? parentMenuItemId;
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

  /// Recursive children for nested menu structure
  final List<MenuItem>? children;

  const MenuItem({
    this.menuItemId,
    this.menuConfigurationId,
    this.parentMenuItemId,
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

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  MenuItem copyWith({
    String? menuItemId,
    String? menuConfigurationId,
    String? parentMenuItemId,
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
    return MenuItem(
      menuItemId: menuItemId ?? this.menuItemId,
      menuConfigurationId: menuConfigurationId ?? this.menuConfigurationId,
      parentMenuItemId: parentMenuItemId ?? this.parentMenuItemId,
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

  @override
  String toString() => 'MenuItem[$menuItemId: $title]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          menuItemId == other.menuItemId;

  @override
  int get hashCode => menuItemId.hashCode;
}

/// Wrapper for list responses
@JsonSerializable(explicitToJson: true)
class MenuItems {
  @JsonKey(name: 'menuItem')
  final List<MenuItem> menuItems;

  const MenuItems({this.menuItems = const []});

  factory MenuItems.fromJson(Map<String, dynamic> json) =>
      _$MenuItemsFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemsToJson(this);
}
