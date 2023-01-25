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

/// menu items at the second level.
/// at the top for web, at the bottom for mobile
class TabItem {
  final Icon icon; // bottom of screen tab icon
  final String label; // label of tab top/bottom
  final Widget form; // form to be displayed in a tab selection
  final String?
      floatButtonRoute; // action bottom routing per tab List at the top, string single at the bottom
  final dynamic floatButtonArgs; // argument for button route.
  final Widget? floatButtonForm; // for dialogs which use navigator internally
  TabItem({
    required this.icon,
    required this.label,
    required this.form,
    this.floatButtonRoute,
    this.floatButtonArgs,
    this.floatButtonForm,
  });
}
