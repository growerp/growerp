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

// This file is deprecated. Use MenuOption and MenuItem from growerp_models instead.
// Keeping for backward compatibility during migration.

import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

/// DEPRECATED: Legacy MenuOption class for backward compatibility
/// Use MenuOption from growerp_models instead
@Deprecated('Use MenuOption from growerp_models instead')
class LegacyMenuOption {
  final String? image;
  final String? selectedImage;
  final String title;
  final String? route;
  final Widget? child;
  final List<TabItem>? tabItems;
  final String? floatButtonRoute;
  final List<UserGroup>? userGroups;
  final dynamic arguments;
  final int? sequenceNum;

  const LegacyMenuOption({
    this.image,
    this.selectedImage,
    required this.title,
    this.route,
    this.child,
    this.tabItems,
    this.floatButtonRoute,
    this.userGroups,
    this.arguments,
    this.sequenceNum,
  });
}

/// DEPRECATED: Legacy TabItem class for backward compatibility
/// Use MenuItem children instead
@Deprecated('Use MenuItem from growerp_models instead')
class TabItem {
  final String? key;
  final String title;
  final Widget? form;
  final String? route;
  final Icon? icon;
  final List<UserGroup>? userGroups;

  const TabItem({
    this.key,
    required this.title,
    this.form,
    this.route,
    this.icon,
    this.userGroups,
  });
}
