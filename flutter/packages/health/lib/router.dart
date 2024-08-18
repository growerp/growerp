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

import 'package:flutter/foundation.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart' as debug;
import 'package:flutter/material.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'menu_options.dart';
import 'package:growerp_models/growerp_models.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  if (debug.kDebugMode) {
    if (kDebugMode) {
      debugPrint('>>>NavigateTo { ${settings.name} '
          'with: ${settings.arguments.toString()} }');
    }
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 0, tabIndex: 0));
    case '/requests':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 1));
    case '/user':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => UserDialog(settings.arguments as User));
    case '/customers':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 2));
    case '/employees':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 3));
    case '/company':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 4));
    case '/website':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 5));
    case '/findoc':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => ShowFinDocDialog(settings.arguments as FinDoc));
    case '/printer':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    default:
      return coreRoute(settings);
  }
}
