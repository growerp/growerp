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
import 'package:flutter/material.dart';

import 'menu_options.dart';
import 'acct_menu_options.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    debugPrint(">>>NavigateTo { ${settings.name} "
        "with: ${settings.arguments.toString()} }");
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 0, tabIndex: 0));
    case '/company':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/tasks':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/orders':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/catalog':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    case '/sales':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/purchase':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 5, tabIndex: 0));
    case '/crm':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
    case '/accounting':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => HomeForm(menuOptions: acctMenuOptions));
    case '/acctSales':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 2, tabIndex: 0));
    case '/acctLedger':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 0));
    case '/acctReports':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 4, tabIndex: 0));
    case '/website':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 5));
    case '/acctSetup':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 5, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}
