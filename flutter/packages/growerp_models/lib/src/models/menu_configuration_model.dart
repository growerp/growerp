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
  @NullableTimestampConverter()
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
