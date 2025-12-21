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

part 'menu_configuration_model.g.dart';

/// Helper functions for isActive Y/N conversion
bool _isActiveFromJson(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is String) return value.toUpperCase() == 'Y';
  return true;
}

String _isActiveToJson(bool value) => value ? 'Y' : 'N';

/// Menu configuration for an application.
/// Can be app-level default or user-specific override.
@JsonSerializable(explicitToJson: true)
class MenuConfiguration {
  final String? menuConfigurationId;
  final String appId;
  final String name;
  final String? description;
  final String? userId;
  @JsonKey(fromJson: _isActiveFromJson, toJson: _isActiveToJson)
  final bool isActive;
  final DateTime? createdDate;

  /// List of top-level menu items (those with no parent) for this configuration
  @JsonKey(name: 'menuItems')
  final List<MenuItem> menuItems;

  const MenuConfiguration({
    this.menuConfigurationId,
    required this.appId,
    required this.name,
    this.description,
    this.userId,
    this.isActive = true,
    this.createdDate,
    this.menuItems = const [],
  });

  factory MenuConfiguration.fromJson(Map<String, dynamic> json) =>
      _$MenuConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$MenuConfigurationToJson(this);

  MenuConfiguration copyWith({
    String? menuConfigurationId,
    String? appId,
    String? name,
    String? description,
    String? userId,
    bool? isActive,
    DateTime? createdDate,
    List<MenuItem>? menuItems,
  }) {
    return MenuConfiguration(
      menuConfigurationId: menuConfigurationId ?? this.menuConfigurationId,
      appId: appId ?? this.appId,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}
