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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'acct_menu_options.dart';
import 'menu_options.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_models/growerp_models.dart' as cat;

Route<dynamic> generateRoute(RouteSettings settings) {
  if (debug.kDebugMode) {
    if (kDebugMode) {
      debugPrint('>>>NavigateTo { ${settings.name} '
          'with: ${settings.arguments.toString()} }');
    }
  }
  final finDocDynamicRoute = orderAccountingRoute(settings);
  if (finDocDynamicRoute != null) return finDocDynamicRoute;

  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 0, tabIndex: 0));
    case '/company':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              ShowCompanyDialog(settings.arguments as Company));
    case '/companies':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 1, tabIndex: 0));
    case '/user':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => UserDialog(settings.arguments as User));
    case '/crm':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 2, tabIndex: 0));
    case '/catalog':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 3, tabIndex: 0));
    case '/category':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              CategoryDialog(settings.arguments as cat.Category));
    case '/orders':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 4, tabIndex: 0));
    case '/findoc':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => ShowFinDocDialog(settings.arguments as FinDoc));
    case '/inventory':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getMenuOptions(context), menuIndex: 5, tabIndex: 0));
    case '/printer':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    case '/accounting':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => HomeForm(menuOptions: getAcctMenuOptions));
    case '/acctSales':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getAcctMenuOptions(context), menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getAcctMenuOptions(context), menuIndex: 2, tabIndex: 0));
    case '/acctLedger':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getAcctMenuOptions(context), menuIndex: 3, tabIndex: 0));
    case '/acctReports':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getAcctMenuOptions(context), menuIndex: 4, tabIndex: 0));
    case '/acctSetup':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => DisplayMenuOption(
              menuList: getAcctMenuOptions(context), menuIndex: 5, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}
