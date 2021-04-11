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

import 'package:core/coreRouter.dart';
import 'package:flutter/material.dart';
import 'package:models/@models.dart';
import 'forms/@forms.dart' as local;
import 'package:core/forms/@forms.dart';
import 'menuItem_data.dart';
import 'package:core/templates/@templates.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> generateRoute(RouteSettings settings) {
  print(">>>NavigateTo { ${settings.name} " +
      "with: ${settings.arguments.toString()} }");
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => local.HomeForm());
    case '/company':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuItem(menuList: menuItems, menuIndex: 1, tabIndex: 0));
    case '/admins':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuItem(menuList: menuItems, menuIndex: 1, tabIndex: 1));
    case '/employees':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuItem(menuList: menuItems, menuIndex: 1, tabIndex: 2));
    case '/reservations':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuItem(menuList: menuItems, menuIndex: 3, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}
