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

part 'onboarding_models.g.dart';

@JsonSerializable(explicitToJson: true)
class OnboardingMenuConfig {
  final String name;
  final String classificationId;
  final List<OnboardingMenuItem> menuItems;

  const OnboardingMenuConfig({
    required this.name,
    required this.classificationId,
    required this.menuItems,
  });

  factory OnboardingMenuConfig.fromJson(Map<String, dynamic> j) =>
      _$OnboardingMenuConfigFromJson(j);

  Map<String, dynamic> toJson() => _$OnboardingMenuConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OnboardingMenuItem {
  final String title;
  final String? iconName;
  final String route;
  final String widgetName;
  final int? sequenceNum;
  final String? tileType;

  const OnboardingMenuItem({
    required this.title,
    this.iconName,
    required this.route,
    required this.widgetName,
    this.sequenceNum,
    this.tileType,
  });

  factory OnboardingMenuItem.fromJson(Map<String, dynamic> j) =>
      _$OnboardingMenuItemFromJson(j);

  Map<String, dynamic> toJson() => _$OnboardingMenuItemToJson(this);
}
