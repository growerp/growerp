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

part 'menu_item_model.g.dart';

/// Helper functions for isActive Y/N conversion
bool _isActiveFromJson(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is String) return value.toUpperCase() == 'Y';
  return true;
}

String _isActiveToJson(bool value) => value ? 'Y' : 'N';

/// MenuItem model - static tab/child items
/// These are reusable items that can be linked to MenuOptions via MenuOptionItem
/// This is a read-only entity populated via seed data
@JsonSerializable(explicitToJson: true)
class MenuItem {
  final String menuItemId;
  final String title;
  final String? iconName;
  final String? widgetName;
  final String? image;
  @JsonKey(fromJson: _isActiveFromJson, toJson: _isActiveToJson)
  final bool isActive;

  /// Sequence number within parent MenuOption (from junction table)
  final int? sequenceNum;

  const MenuItem({
    required this.menuItemId,
    required this.title,
    this.iconName,
    this.widgetName,
    this.image,
    this.isActive = true,
    this.sequenceNum,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  MenuItem copyWith({
    String? menuItemId,
    String? title,
    String? iconName,
    String? widgetName,
    String? image,
    bool? isActive,
    int? sequenceNum,
  }) {
    return MenuItem(
      menuItemId: menuItemId ?? this.menuItemId,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      widgetName: widgetName ?? this.widgetName,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      sequenceNum: sequenceNum ?? this.sequenceNum,
    );
  }
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
