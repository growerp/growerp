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

import 'package:flutter/material.dart';
import 'package:core/domains/domains.dart';

/// item on the main menu, containing tabitems on a lower level.
class MenuOption {
  // main menu item shown on the left or in drawer
  final String image; // image when not seleced
  final String selectedImage; // image when selected
  final String title; // a the top of the page
  final String route; // route path required to show this item
  final List<TabItem>? tabItems; // top/bottom tabs
  final Widget? child; // when no tabs this is single page
  final Widget? leadAction; // single actionButton on the left like back button
  final List<UserGroup> readGroups; // user groups who can read
  final List<UserGroup>? writeGroups; // user groups who can add/update/delete
  final Widget? floatButtonForm; // for dialogs which use navigator internally

  MenuOption({
    required this.image,
    required this.selectedImage,
    required this.title,
    required this.route,
    this.tabItems,
    this.child,
    this.leadAction,
    required this.readGroups,
    this.writeGroups,
    this.floatButtonForm,
  });

  @override
  String toString() => 'MenuOption name: $title route: $route '
      'tabItems# ${tabItems != null ? tabItems!.length : "0"}';
}
